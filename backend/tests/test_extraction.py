import json

import httpx
import pytest
from fastapi.testclient import TestClient

from extraction import ExtractionRequest, ExtractionResult, OllamaTaskExtractor, validate_result, resolve_deadline
from main import create_app


def request(text="明天买牛奶"):
    return ExtractionRequest(text=text, current_time="2026-10-08T22:30:00Z", timezone="Asia/Shanghai")


def task(**changes):
    value = dict(title="买牛奶", description=None, category="生活", horizon="recently",
                 deadline=None, suggestedStart=None, priority="medium", evidence="明天买牛奶",
                 deadline_evidence=None, priority_evidence=None, start_evidence=None,
                 startPeriod=None, deadlinePeriod=None, firstStep=None, firstStepReason=None)
    value.update(changes)
    return value


def result(*tasks):
    return ExtractionResult.model_validate({"tasks": tasks, "cancellations": []})


def test_advice_is_one_action_and_task_benefit_not_procedural_copy():
    extracted = result(task(
        firstStep="打开文件或查看清单。再整理内容。",
        firstStepReason="整洁的空间让日常取用更方便。加油！",
        recommendationReason="用户明确表达需要整理",
    )).tasks[0]
    assert extracted.firstStep == "打开文件。"
    assert extracted.firstStepReason == "整洁的空间让日常取用更方便。"
    assert extracted.recommendationReason == "你提到需要整理"
    assert result(task(firstStepReason="准备好工具能立即开始")).tasks[0].firstStepReason is None
    assert result(task(recommendationReason="今天时间充裕可以安排")).tasks[0].recommendationReason is None


def test_ollama_uses_schema_non_thinking_and_device_context():
    calls = []
    def handle(req):
        if req.method == "GET": return httpx.Response(200, json={"models": []})
        calls.append(json.loads(req.content))
        return httpx.Response(200, json={"response": json.dumps({"tasks": [task()], "cancellations": []}), "load_duration": 1000000,
                                        "prompt_eval_duration": 2500000, "eval_duration": 8000000,
                                        "prompt_eval_count": 100, "eval_count": 40})
    service = OllamaTaskExtractor(client=httpx.Client(transport=httpx.MockTransport(handle)))
    extracted = service.extract(request())
    assert extracted["tasks"][0]["deadline"] is None
    assert extracted["timings"]["load_state"] == "cold"
    assert extracted["timings"]["model_load_ms"] == 1
    assert extracted["timings"]["prompt_eval_ms"] == 2.5
    assert extracted["timings"]["generation_ms"] == 8
    assert extracted["timings"]["prompt_tokens"] == 100
    assert extracted["timings"]["output_tokens"] == 40
    assert extracted["timings"]["postprocess_ms"] >= 0
    assert len(calls) == 1
    call = calls[0]
    assert call["think"] is False and call["stream"] is False
    assert call["format"]["properties"]["tasks"]["type"] == "array"
    assert {"startSuggested", "prioritySuggested", "recommendationReason"} <= set(call["format"]["$defs"]["ExtractedTask"]["required"])
    assert call["options"]["temperature"] == 0
    assert '"timezone": "Asia/Shanghai"' in call["prompt"]
    assert call["raw"] is True
    assert call["prompt"].endswith("<think>\n\n</think>\n\n")
    service.close()


@pytest.mark.parametrize("context, expected", [(32768, "warm"), (8192, "cold")])
def test_resident_model_with_different_context_is_not_a_warm_runner(context, expected):
    def handle(req):
        if req.method == "GET":
            return httpx.Response(200, json={"models": [{"name": "qwen3.5:4b", "context_length": context}]})
        return httpx.Response(200, json={"response": json.dumps({"tasks": [task()], "cancellations": []})})
    service = OllamaTaskExtractor(client=httpx.Client(transport=httpx.MockTransport(handle)))
    assert service.extract(request())["timings"]["load_state"] == expected
    service.close()


def test_unspecified_priority_and_planned_tomorrow_are_not_deadlines():
    output = validate_result(result(task(priority="high", deadline="2026-10-10", deadline_evidence="明天买牛奶")), request())
    assert output["tasks"][0]["priority"] == "medium"
    assert output["tasks"][0]["deadline"] is None


def test_relative_deadline_uses_device_date_and_rejects_wrong_day():
    text = "必须在明天之前提交报告"
    value = task(title="提交报告", evidence=text, deadline_evidence=text, deadline="2026-10-10")
    assert validate_result(result(value), request(text))["tasks"][0]["deadline"] == "2026-10-10"
    value["deadline"] = "2026-10-09"
    assert validate_result(result(value), request(text))["tasks"][0]["deadline"] == "2026-10-10"


def test_hallucinated_evidence_and_invented_clock_time_are_rejected():
    with pytest.raises(ValueError):
        validate_result(result(task(evidence="买咖啡")), request())
    text = "最晚明天提交报告"
    assert validate_result(result(task(evidence=text, deadline_evidence=text, deadline="2026-10-10T17:00+08:00")), request(text))["tasks"][0]["deadline"] == "2026-10-10"


def test_no_tasks_and_duplicates():
    assert validate_result(result(), request()) == {"tasks": [], "cancellations": []}
    assert len(validate_result(result(task(), task()), request())["tasks"]) == 1


def test_explicit_chinese_clock_and_unknown_date():
    from datetime import datetime
    from zoneinfo import ZoneInfo
    now = datetime(2026, 10, 8, 23, 30, tzinfo=ZoneInfo("Europe/Berlin"))
    assert resolve_deadline("明天下午三点半之前提交", now, "Europe/Berlin") == "2026-10-09T15:30+02:00"
    assert resolve_deadline("截止下周五提交", now, "Europe/Berlin") == "2026-10-16"
    assert resolve_deadline("截止时间待定", now, "Europe/Berlin") is None
    assert resolve_deadline("明天下午三点去运动", now, "Europe/Berlin") is None


def test_api_failure_invalid_context_and_retry():
    class FakeExtractor:
        def __init__(self): self.calls = 0
        def extract(self, value):
            self.calls += 1
            if self.calls == 1: raise ValueError("Invalid JSON")
            return {"tasks": []}
        def close(self): pass
    with TestClient(create_app(transcriber=object(), extractor=FakeExtractor())) as client:
        payload = request().model_dump(mode="json")
        assert client.post("/extract-tasks", json=payload).status_code == 502
        assert client.post("/extract-tasks", json=payload).json() == {"tasks": []}
        payload["timezone"] = "Invalid/Timezone"
        assert client.post("/extract-tasks", json=payload).status_code == 422
        payload["timezone"] = "UTC"
        payload["text"] = " "
        assert client.post("/extract-tasks", json=payload).status_code == 422


def test_planned_start_preserves_date_minute_and_midnight_precision():
    from datetime import datetime
    from zoneinfo import ZoneInfo
    from extraction import resolve_time
    now = datetime(2026, 10, 8, 23, 30, tzinfo=ZoneInfo("Europe/Berlin"))
    assert resolve_time("明天买鸡蛋", now, "Europe/Berlin") == "2026-10-09"
    assert resolve_time("明天下午三点给妈妈打电话", now, "Europe/Berlin") == "2026-10-09T15:00+02:00"
    assert resolve_time("明天零点提交", now, "Europe/Berlin") == "2026-10-09T00:00+02:00"
    assert resolve_time("下午三点打电话", now, "Europe/Berlin") == "2026-10-08T15:00+02:00"
    text = "明天下午三点给妈妈打电话，最晚后天完成"
    value = validate_result(result(task(title="给妈妈打电话", evidence=text,
        start_evidence="明天下午三点给妈妈打电话", deadline_evidence="最晚后天完成")), request(text))["tasks"][0]
    assert value["suggestedStart"] == "2026-10-10T15:00+08:00"
    assert value["deadline"] == "2026-10-11"


def test_high_priority_and_category_allowlist():
    text = "必须提交申请，这个很重要"
    value = task(title="提交申请", evidence=text, priority="high", priority_evidence="很重要")
    assert validate_result(result(value), request(text))["tasks"][0]["priority"] == "high"
    for category in (None, "运动", "爱好", "未知"):
        with pytest.raises(ValueError): result(task(category=category))


def test_valid_seconds_are_normalized_but_current_clock_is_not_task_evidence():
    value = task(suggestedStart="2026-10-09T06:30:41.123456+08:00")
    parsed = result(value)
    assert parsed.tasks[0].suggestedStart == "2026-10-09T06:30+08:00"
    assert validate_result(parsed, request())["tasks"][0]["suggestedStart"] == "2026-10-10"
    text = "买牛奶"
    parsed = result(task(evidence=text, suggestedStart="2026-10-09T06:30:41+08:00"))
    planned = validate_result(parsed, request(text))["tasks"][0]
    assert planned["suggestedStart"] is None
    assert planned["startSuggested"] is False
    for invalid in ("2026-02-30", "2026-10-09T25:00+08:00", "2026-10-09T06:30"):
        with pytest.raises(ValueError): result(task(suggestedStart=invalid))


def test_periods_are_independent_and_explicit_clock_wins():
    text = "今晚买牛奶，最晚明天晚上完成"
    value = validate_result(result(task(evidence=text, start_evidence="今晚买牛奶", deadline_evidence="最晚明天晚上完成")), request(text))["tasks"][0]
    assert (value["suggestedStart"], value["startPeriod"]) == ("2026-10-09", "晚上")
    assert (value["deadline"], value["deadlinePeriod"]) == ("2026-10-10", "晚上")
    text = "明天下午三点买牛奶"
    value = validate_result(result(task(evidence=text)), request(text))["tasks"][0]
    assert value["suggestedStart"] == "2026-10-10T15:00+08:00" and value["startPeriod"] is None


def test_replacement_inherits_original_period_and_advice_is_not_a_task():
    text = "晚上不用买牛奶了，我想改为买鸡蛋"
    req = request(text)
    req.existing_tasks = [__import__('extraction').ExistingTask(id="milk", title="买牛奶")]
    plan = ExtractionResult.model_validate({"tasks": [task(title="买鸡蛋", evidence="我想改为买鸡蛋", start_evidence="晚上", firstStep="先确认鸡蛋数量", firstStepReason="明确数量便于购买")], "cancellations": [{"target": "买牛奶", "evidence": "晚上不用买牛奶了", "candidate_ids": ["milk"]}]})
    value = validate_result(plan, req)
    assert len(value["tasks"]) == 1
    assert value["tasks"][0]["startPeriod"] == "晚上"
    assert value["tasks"][0]["suggestedStart"] == "2026-10-09"
    assert value["tasks"][0]["firstStep"] == "先确认鸡蛋数量。"
    assert value["cancellations"][0]["candidate_ids"] == ["milk"]


@pytest.mark.parametrize("day,horizon", [(8,"today"), (11,"recently"), (12,"later")])
def test_date_grouping_uses_resolved_local_day_not_model_horizon(day, horizon):
    text = f"2026-10-{day:02d}买牛奶"
    req = ExtractionRequest(text=text, current_time="2026-10-08T23:59:56+02:00", timezone="Europe/Berlin")
    value = validate_result(result(task(evidence=text, horizon="later")), req)["tasks"][0]
    assert value["horizon"] == horizon


def test_short_period_evidence_keeps_date_in_original_clause_and_different_periods_are_distinct():
    text = "明天下午买牛奶"
    value = validate_result(result(task(evidence=text, start_evidence="下午")), request(text))["tasks"][0]
    assert (value["suggestedStart"],value["startPeriod"]) == ("2026-10-10","下午")
    text = "上午跑步，晚上跑步"
    value = validate_result(result(task(title="跑步", evidence="上午跑步"), task(title="跑步", evidence="晚上跑步")), request(text))
    assert len(value["tasks"]) == 2


def test_cancel_existing_ids_expands_ambiguous_matches_and_no_match_is_safe():
    text = "不用买牛奶了，明天只买鸡蛋"
    payload = dict(text=text, current_time="2026-10-08T23:30+02:00", timezone="Europe/Berlin",
        existing_tasks=[{"id":"milk-1","title":"买牛奶"},{"id":"milk-2","title":"买牛奶"}])
    proposal = ExtractionResult.model_validate({"tasks":[task(title="买鸡蛋", evidence="明天只买鸡蛋")],
        "cancellations":[{"target":"买牛奶","evidence":"不用买牛奶了","candidate_ids":["milk-1"]}]})
    response = validate_result(proposal, ExtractionRequest(**payload))
    assert response["cancellations"][0]["candidate_ids"] == ["milk-1", "milk-2"]
    proposal.cancellations[0].candidate_ids = ["invented"]
    with pytest.raises(ValueError): validate_result(proposal, ExtractionRequest(**payload))
    proposal.cancellations[0].candidate_ids = []
    payload["existing_tasks"] = []
    assert validate_result(proposal, ExtractionRequest(**payload))["cancellations"] == []
    with pytest.raises(ValueError): validate_result(result(task(evidence="不用买牛奶了")), request(text))


@pytest.mark.parametrize("text,guess,expected,period", [
    ("明天下午三点给妈妈打电话", "2026-10-09T15:00", "2026-10-10T15:00+08:00", None),
    ("今晚买牛奶", "2026-10-09T19:00", "2026-10-09", "晚上"),
    ("买牛奶", "2026-10-09T06:30+08:00", None, None),
    ("三天后买牛奶", None, "2026-10-12", None),
    ("四天后买牛奶", None, "2026-10-13", None),
])
def test_provider_time_guesses_are_replaced_by_verified_source(text, guess, expected, period):
    def handle(req):
        if req.method == "GET":
            return httpx.Response(200, json={"models": []})
        value = task(evidence=text, suggestedStart=guess, startPeriod="晚上", description="null")
        return httpx.Response(200, json={"response": json.dumps({"tasks": [value], "cancellations": []})})
    service = OllamaTaskExtractor(client=httpx.Client(transport=httpx.MockTransport(handle)))
    output = service.extract(request(text))["tasks"][0]
    assert (output["suggestedStart"], output["startPeriod"], output["deadline"]) == (expected, period, None)
    assert output["startSuggested"] is False
    assert "建议理由：" in output["description"]
    service.close()


def test_independent_time_evidence_is_used_without_copying_request_clock():
    text = "必须提交申请，这个很重要，后天晚上之前交上去"
    value = task(title="提交申请", evidence="必须提交申请", deadline_evidence="后天晚上之前交上去")
    output = validate_result(result(value), request(text))["tasks"][0]
    assert (output["deadline"], output["deadlinePeriod"], output["suggestedStart"]) == ("2026-10-11", "晚上", None)
    assert output["startSuggested"] is False


def test_obstacles_keep_intent_and_priority_suggestion_without_fake_evidence():
    text = "想出去吃好吃的，但是太远很耗时"
    value = validate_result(result(task(title="出去吃好吃的", evidence=text,
        priority="low", prioritySuggested=True, description="太远很耗时")), request(text))["tasks"][0]
    assert value["priority"] == "low" and value["prioritySuggested"]
    assert value["description"].startswith("太远很耗时\n建议理由：")
    assert len(validate_result(result(task(title="化妆拍照", evidence="特别想化妆拍照")), request("特别想化妆拍照"))["tasks"]) == 1


def test_missing_proposal_does_not_build_fake_slots_and_leaves_explicit_date_untouched():
    req = request("买鸡蛋，明天打扫房间")
    from extraction import ExistingTask
    req.existing_tasks = [ExistingTask(id="old", title="旧安排", suggestedStart="2026-10-09T07:00+08:00")]
    values = validate_result(result(task(title="买鸡蛋", evidence="买鸡蛋"),
        task(title="打扫房间", evidence="明天打扫房间")), req)["tasks"]
    assert values[0]["suggestedStart"] is None
    assert values[0]["startSuggested"] is False
    assert values[1]["suggestedStart"] == "2026-10-10"
    assert values[1]["startSuggested"] is False


def test_explicit_literal_cancellation_is_recovered_but_barriers_are_not_deletions():
    from extraction import ExistingTask
    req = request("晚上不用买牛奶了，我想改为买鸡蛋")
    req.existing_tasks = [ExistingTask(id="milk", title="买牛奶")]
    output = validate_result(result(task(title="买鸡蛋", evidence="我想改为买鸡蛋")), req)
    assert output["cancellations"] == [{"target": "买牛奶", "candidate_ids": ["milk"]}]
    assert output["tasks"][0]["startPeriod"] == "晚上"
    req.text = "想买牛奶，但是太远了"
    output = validate_result(result(task(evidence="想买牛奶")), req)
    assert output["cancellations"] == []
    assert "太远" in output["tasks"][0]["description"]


@pytest.mark.parametrize("word,priority", [("高", "high"), ("中", "medium"), ("低", "low")])
def test_user_named_priority_and_time_override_model_recommendation(word, priority):
    text = f"明天下午三点写代码，{word}优先级"
    value = task(title="写代码", evidence="明天下午三点写代码", priority="high",
        prioritySuggested=True, priority_evidence=f"{word}优先级", startSuggested=True,
        suggestedStart="2026-10-12", recommendationReason="优先开始")
    output = validate_result(result(value), request(text))["tasks"][0]
    assert output["priority"] == priority and not output["prioritySuggested"]
    assert output["suggestedStart"] == "2026-10-10T15:00+08:00"
    assert output["startSuggested"] is False


def test_obligation_orders_before_equivalent_wish_without_automatic_high():
    text = "想化妆拍照，但我必须写代码"
    wish = task(title="化妆拍照", evidence="想化妆拍照", prioritySuggested=True)
    obligation = task(title="写代码", evidence="但我必须写代码", priority="high", prioritySuggested=True)
    output = validate_result(result(wish, obligation), request(text))["tasks"]
    assert [value["title"] for value in output] == ["写代码", "化妆拍照"]
    assert [value["priority"] for value in output] == ["medium", "medium"]
    assert all("建议理由：" in value["description"] for value in output)


def test_coarse_proposals_use_periods_and_allow_later_days_without_clock_slots():
    text = "必须写代码，想出去吃好吃的但路远耗时"
    values = [task(title="写代码", evidence="必须写代码", startSuggested=True,
                   suggestedStart="2026-10-09T07:30+08:00", prioritySuggested=True),
              task(title="出去吃好吃的", evidence="想出去吃好吃的但路远耗时", startSuggested=True,
                   suggestedStart="2026-10-13", startPeriod="下午", priority="low", prioritySuggested=True,
                   recommendationReason="路远耗时，建议以后再安排，仅为粗略计划")]
    output = validate_result(result(*values), request(text))["tasks"]
    assert output[0]["suggestedStart"] == "2026-10-09"
    assert output[1]["suggestedStart"] == "2026-10-13" and output[1]["horizon"] == "later"
    assert output[1]["startPeriod"] == "下午"
    assert all(value["startSuggested"] and "T" not in value["suggestedStart"] for value in output)


def test_past_suggested_period_and_conflict_guarantee_are_not_accepted():
    text = "想拍照"
    req = ExtractionRequest(text=text, current_time="2026-10-11T15:00+02:00", timezone="Europe/Berlin")
    value = task(title="拍照", evidence=text, startSuggested=True, suggestedStart="2026-10-11",
                 startPeriod="上午", recommendationReason="安排无冲突，保证有足够空闲")
    output = validate_result(result(value), req)["tasks"][0]
    assert output["suggestedStart"] is None and output["startPeriod"] is None
    assert "未核实" in output["description"] or "未知" in output["description"]
    assert "无冲突" not in output["description"]


def test_undated_coarse_group_matches_recommendation_copy_without_invented_date():
    text = "想出去吃好吃的但路远耗时"
    value = task(title="出去吃好吃的", evidence=text, horizon="later", priority="low", prioritySuggested=True,
                 recommendationReason="路远耗时，建议近期安排")
    output = validate_result(result(value), request(text))["tasks"][0]
    assert output["horizon"] == "later" and output["suggestedStart"] is None
    assert "建议以后安排" in output["description"]


def test_only_leading_connector_can_be_reanchored_to_unique_verbatim_action():
    from extraction import canonical_action_evidence
    text = "然后呢，我又很想化妆拍照，但是呢又很懒"
    payload = {"tasks": [task(title="化妆拍照", evidence="但是我又很想化妆拍照")] , "cancellations": []}
    fixed = canonical_action_evidence(payload, request(text))
    assert fixed["tasks"][0]["evidence"] == "我又很想化妆拍照"
    output = validate_result(ExtractionResult.model_validate(fixed), request(text))
    assert len(output["tasks"]) == 1 and output["cancellations"] == []
    assert "懒" in output["tasks"][0]["description"]


@pytest.mark.parametrize("source,evidence", [
    ("我又很想化妆拍照", "但是我又很想旅游拍照"),
    ("不用化妆拍照了", "但是化妆拍照了"),
    ("我已经化妆拍照了", "但是化妆拍照了"),
    ("我又很想化妆拍照，我又很想化妆拍照", "但是我又很想化妆拍照"),
    ("我又很想化妆拍照", "但是我又不想化妆拍照"),
])
def test_reanchoring_rejects_changed_action_negation_completed_and_ambiguous_quotes(source, evidence):
    from extraction import canonical_action_evidence
    payload = {"tasks": [task(title="化妆拍照", evidence=evidence)], "cancellations": []}
    fixed = canonical_action_evidence(payload, request(source))
    assert fixed["tasks"][0]["evidence"] == evidence
    with pytest.raises(ValueError):
        validate_result(ExtractionResult.model_validate(fixed), request(source))


def test_invalid_batch_logs_raw_model_diagnostics_and_returns_no_partial_plan(caplog):
    raw = json.dumps({"tasks": [task(), task(title="旅行", evidence="虚构的旅行")], "cancellations": []}, ensure_ascii=False)
    def handle(req):
        if req.method == "GET": return httpx.Response(200, json={"models": []})
        return httpx.Response(200, json={"response": raw, "done_reason": "stop", "eval_count": 123})
    service = OllamaTaskExtractor(client=httpx.Client(transport=httpx.MockTransport(handle)))
    with TestClient(create_app(transcriber=object(), extractor=service)) as client:
        response = client.post("/extract-tasks", json=request().model_dump(mode="json"))
    assert response.status_code == 502 and "未通过校验" in response.json()["detail"]
    assert "tasks" not in response.json()
    assert "虚构的旅行" in caplog.text and "output_tokens=123" in caplog.text
    assert "raw_response=" in caplog.text and "model_ms=" in caplog.text


@pytest.mark.parametrize("kind,status,message", [("timeout",504,"超时"), ("connection",502,"无法连接"), ("length",502,"不完整")])
def test_extraction_errors_distinguish_timeout_connection_and_truncation(kind,status,message):
    def handle(req):
        if kind == "timeout": raise httpx.ReadTimeout("slow", request=req)
        if kind == "connection": raise httpx.ConnectError("offline", request=req)
        if req.method == "GET": return httpx.Response(200, json={"models": []})
        return httpx.Response(200, json={"response": '{"tasks":', "done_reason": "length"})
    service = OllamaTaskExtractor(client=httpx.Client(transport=httpx.MockTransport(handle)))
    with TestClient(create_app(transcriber=object(), extractor=service)) as client:
        response = client.post("/extract-tasks", json=request().model_dump(mode="json"))
    assert response.status_code == status and message in response.json()["detail"]
    assert "tasks" not in response.json()


def test_captured_real_4b_failure_preserves_all_four_intents_without_cancellations():
    import copy
    from pathlib import Path
    from extraction import canonical_action_evidence, canonical_model_times, ExistingTask
    fixture = json.loads((Path(__file__).parent / "fixtures" / "oral_connector_failure.json").read_text(encoding="utf8"))
    req = ExtractionRequest.model_validate(fixture["request"])
    req.existing_tasks = [ExistingTask(id="old", title="买牛奶")]
    before = req.model_dump()
    raw = copy.deepcopy(fixture["model_response"])
    with pytest.raises(ValueError, match="Task evidence absent"):
        validate_result(ExtractionResult.model_validate(canonical_model_times(raw, req)), req)
    raw = canonical_action_evidence(copy.deepcopy(fixture["model_response"]), req)
    output = validate_result(ExtractionResult.model_validate(canonical_model_times(raw, req)), req)
    assert [item["title"] for item in output["tasks"]] == ["写代码", "打扫房间", "出去吃好吃的", "化妆拍照"]
    assert output["cancellations"] == []
    assert req.model_dump() == before
