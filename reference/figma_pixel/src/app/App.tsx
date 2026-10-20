import { useEffect, useRef, useState, type ReactNode } from "react"
import {
  createBrowserRouter,
  RouterProvider,
  useNavigate,
  useLocation,
} from "react-router"
import {
  ArrowLeft,
  ArrowUpRight,
  BatteryFull,
  CalendarDays,
  Check,
  ChevronRight,
  ListTodo,
  Mic,
  Pencil,
  Plus,
  Signal,
  Square,
  Sun,
  Tag,
  Trash2,
  Wifi,
  Sparkles,
} from "lucide-react"

type Task = {
  id: number
  title: string
  category: string
  time: string
  duration: string
  priority: string
  period: string
  done: boolean
}
const initialTasks: Task[] = [
  {
    id: 1,
    title: "整理网站改版思路",
    category: "工作",
    time: "10:00",
    duration: "45 分钟",
    priority: "高",
    period: "今天",
    done: false,
  },
  {
    id: 2,
    title: "预约牙齿检查",
    category: "生活",
    time: "12:30",
    duration: "10 分钟",
    priority: "中",
    period: "今天",
    done: false,
  },
  {
    id: 3,
    title: "出门走走，放松一下",
    category: "健康",
    time: "17:00",
    duration: "20 分钟",
    priority: "中",
    period: "今天",
    done: false,
  },
  {
    id: 4,
    title: "把旅行照片发给小林",
    category: "生活",
    time: "不限时间",
    duration: "5 分钟",
    priority: "低",
    period: "今天",
    done: false,
  },
  {
    id: 5,
    title: "读完书里的下一章",
    category: "生活",
    time: "20:30",
    duration: "20 分钟",
    priority: "低",
    period: "今天",
    done: false,
  },
  {
    id: 6,
    title: "安排这周的晚餐",
    category: "生活",
    time: "明天",
    duration: "25 分钟",
    priority: "中",
    period: "近期",
    done: false,
  },
  {
    id: 7,
    title: "找一堂周末陶艺课",
    category: "生活",
    time: "下周",
    duration: "15 分钟",
    priority: "低",
    period: "以后",
    done: false,
  },
]
const destinations = { 今天: "/", 记录: "/capture", 任务: "/tasks" }
type PixelIconKind = "gem" | "chest" | "sword" | "scroll" | "heart" | "crown"
function PixelIcon({ kind, className = "" }: { kind: PixelIconKind; className?: string }) {
  const paths: Record<PixelIconKind, string> = {
    gem: "M6 2h12v3h3v9h-3v3h-3v3h-3v3H9v-3H6v-3H3V5h3z",
    chest: "M5 3h14v3h3v15H2V6h3zM2 10h20v3H2z",
    sword: "M17 1h6v6h-3v3h-3v3h-3v3h3v3h-6v-3H8v3H5v3H2v-3h3v-3h3v-3H5v-3h3v3h3V9h3V6h3z",
    scroll: "M4 2h15v3h3v4h-3V5H7v14h12v-3h3v6H4v-3H1V5h3zM10 8h6v2h-6zM10 12h6v2h-6z",
    heart: "M3 3h6v3h6V3h6v3h3v9h-3v3h-3v3h-3v3H9v-3H6v-3H3v-3H0V6h3z",
    crown: "M1 4h3v3h3v3h3V3h4v7h3V7h3V4h3v15H1zM4 21h16v3H4z",
  }
  return (
    <svg className={`pixel-icon ${className}`} viewBox="0 0 24 24" aria-hidden="true" shapeRendering="crispEdges">
      <path d={paths[kind]} fill="currentColor" />
      {kind === "chest" && <path d="M10 9h4v7h-4z" className="pixel-face" />}
      {kind === "gem" && <path d="M7 5h5v3H7zM5 8h3v5H5z" className="pixel-gem-shine" />}
    </svg>
  )
}
function PixelScene({ compact = false, quest = false, energy = 0 }: { compact?: boolean; quest?: boolean; energy?: number }) {
  return (
    <svg className={`pixel-scene adventure-stage energy-${energy} ${compact ? "pixel-scene-compact" : ""}`} viewBox="0 0 320 104" aria-hidden="true" shapeRendering="crispEdges">
      <path className="pixel-star" d="M20 14h3v3h-3zM57 34h2v2h-2zM112 12h3v3h-3zM155 29h2v2h-2zM206 12h3v3h-3zM290 32h3v3h-3zM176 54h2v2h-2zM85 54h2v2h-2z" />
      <path className="pixel-moon" d="M246 12h20v4h8v8h4v16h-4v8h-8v4h-20v-4h-8v-8h-4V24h4v-8h8z" />
      <path className="pixel-moon-shade" d="M246 16h8v8h-8zM264 32h8v8h-8zM242 36h4v4h-4z" />
      <path className="pixel-mountain" d="M0 74h20V62h16V50h20V38h16v12h16v12h20v12h20v10h30V68h20V56h18V44h20v12h16v12h20v12h24V68h20V56h18v12h22v36H0z" />
      <path className="pixel-mountain-near" d="M0 90h38V78h22V66h20v12h22v12h38v-8h26v-12h20v12h24v10h40V82h20V72h20v10h30v22H0z" />
      <path className="pixel-ground" d="M0 98h320v6H0z" />
      <path className="pixel-grass" d="M0 96h80v4H0zM112 96h58v4h-58zM228 96h92v4h-92z" />
      {quest && <>
        <path className="pixel-castle" d="M28 60h8v8h8v-8h8v8h8v-8h8v36H28zM34 40h8v8h8v-8h8v20H34z" />
        <path className="pixel-face" d="M42 80h12v16H42zM40 54h4v6h-4zM52 54h4v6h-4z" />
        <path className="adventure-trail" d="M76 94h24v2H76zM118 94h24v2h-24zM160 94h24v2h-24zM202 94h24v2h-24z" />
        <g className="treasure-glow">
          <path className="pixel-moon" d="M262 70h4v6h-4zM276 68h4v8h-4zM270 62h3v5h-3z" />
          <path className="pixel-character" d="M264 76h14v4h-14z" />
        </g>
        <path className="pixel-moon" d="M254 86h32v10h-32z" />
        <path className="pixel-face" d="M254 86h32v3h-32zM267 87h6v6h-6z" />
        <g className="treasure-lid">
          <path className="pixel-moon" d="M258 80h24v4h4v3h-32v-3h4z" />
          <path className="pixel-moon-shade" d="M258 81h24v2h-24z" />
        </g>
      </>}
      <g className="adventure-walker">
        <path className="pixel-character-shadow" d="M141 92h26v4h-26z" />
        <g key={energy} className={energy > 0 ? "walker-step" : "walker-idle"}>
          <path className="pixel-character" d="M148 67h12v4h4v12h-4v8h-4v-8h-4v8h-4V79h-4v-8h4z" />
          <path className="pixel-face" d="M152 71h8v4h-8z" />
          <path className="pixel-sword" d="M170 69h4v18h-4zM166 81h12v4h-12z" />
        </g>
      </g>
    </svg>
  )
}
function PixelCaptureScene({ recording = false }: { recording?: boolean }) {
  return (
    <svg className={`pixel-scene pixel-capture-scene ${recording ? "is-listening" : ""}`} viewBox="0 0 320 104" aria-hidden="true" shapeRendering="crispEdges">
      {/* A listening station turns floating ideas into neatly filed notes. */}
      <path className="capture-grid" d="M0 24h320v1H0zM0 48h320v1H0zM0 72h320v1H0zM32 0h1v104h-1zM64 0h1v104h-1zM96 0h1v104h-1zM128 0h1v104h-1zM160 0h1v104h-1zM192 0h1v104h-1zM224 0h1v104h-1zM256 0h1v104h-1zM288 0h1v104h-1z" />
      <path className="capture-spark" d="M38 18h4v-4h4v4h4v4h-4v4h-4v-4h-4zM275 20h4v-4h4v4h4v4h-4v4h-4v-4h-4zM93 8h3v3h-3zM224 12h3v3h-3z" />
      <g className="capture-floating-note">
        <path className="capture-note" d="M58 35h24v28H58z" />
        <path className="pixel-face" d="M63 41h14v3H63zM63 48h10v3H63z" />
      </g>
      <g className="capture-floating-note capture-note-right">
        <path className="capture-note" d="M236 40h26v24h-26z" />
        <path className="pixel-face" d="M241 46h16v3h-16zM241 53h11v3h-11z" />
      </g>
      <g className="capture-flow">
        <path className="capture-signal" d="M92 46h4v4h-4z" />
        <path className="capture-signal" d="M104 46h4v4h-4z" />
        <path className="capture-signal" d="M116 46h4v4h-4z" />
        <path className="capture-signal" d="M217 46h4v4h-4z" />
        <path className="capture-signal" d="M205 46h4v4h-4z" />
      </g>
      <path className="capture-antenna" d="M158 20h4v14h-4zM154 14h12v8h-12z" />
      <path className="capture-machine" d="M134 32h52v4h6v38h-6v4h-52v-4h-6V36h6z" />
      <path className="pixel-face" d="M136 40h48v24h-48z" />
      <g className="capture-wave-bars">
        {["M143 49h3v6h-3z", "M149 45h3v14h-3z", "M155 42h3v20h-3z", "M161 47h3v10h-3z", "M167 44h3v16h-3z", "M173 49h3v6h-3z"].map((path) => <path key={path} className="capture-wave" d={path} />)}
      </g>
      <path className="capture-controls" d="M140 69h4v4h-4zM148 69h4v4h-4zM170 69h10v4h-10z" />
      <path className="capture-desk" d="M114 80h92v6h-92zM120 86h6v12h-6zM194 86h6v12h-6z" />
      <path className="capture-files" d="M62 79h28v5H62zM58 86h32v5H58zM242 77h22v4h8v14h-38V81h8z" />
      <path className="capture-signal" d="M249 84h9v3h-9z" />
      <path className="pixel-ground" d="M0 98h320v6H0z" />
    </svg>
  )
}
function StatusBar() {
  return (
    <div className="flex h-[58px] shrink-0 items-center justify-between px-7 text-[14px] font-semibold">
      <span>9:41</span>
      <div className="flex items-center gap-1">
        <Signal size={15} fill="currentColor" />
        <Wifi size={15} />
        <BatteryFull size={22} />
      </div>
    </div>
  )
}
function HomeIndicator() {
  return (
    <div className="mx-auto mb-2 mt-2 h-[5px] w-[112px] shrink-0 rounded-full bg-[#18191b]" />
  )
}
function BottomNav({
  active,
  go,
}: {
  active: string
  go: (screen: keyof typeof destinations) => void
}) {
  return (
    <div className="game-nav shrink-0 border-t border-black/5 bg-white/80">
      <div className="flex h-[62px] items-center justify-around">
        {[
          { name: "今天", icon: Sun },
          { name: "记录", icon: Mic },
          { name: "任务", icon: ListTodo },
        ].map(({ name, icon: Icon }) => (
          <button
            key={name}
            onClick={() => go(name as keyof typeof destinations)}
            className={`flex h-full w-20 flex-col items-center justify-center gap-1 text-[10px] font-medium ${
              active === name ? "text-primary" : "text-[#939497]"
            }`}
          >
            <Icon size={23} strokeWidth={active === name ? 2 : 1.6} />
            {name}
          </button>
        ))}
      </div>
      <HomeIndicator />
    </div>
  )
}
function ScreenFrame({
  children,
  label,
  visible,
}: {
  children: ReactNode
  label: string
  visible: boolean
}) {
  return (
    <section className={`game-screen ${visible ? "block" : "hidden"} min-w-0 lg:block`}>
      <div className="mb-4 hidden text-center text-[12px] font-medium text-[#85888c] lg:block">
        {label}
      </div>
      <div className="pixel-device relative mx-auto flex h-[100dvh] min-h-[700px] w-full flex-col overflow-hidden bg-background lg:h-[820px] lg:min-h-0 lg:max-w-[393px] lg:border-[7px] lg:border-border">
        <div className="pointer-events-none absolute left-1/2 top-3 hidden h-[23px] w-[84px] -translate-x-1/2 rounded-full bg-[#18191b] lg:block" />
        <StatusBar />
        {children}
      </div>
    </section>
  )
}
function TaskCard({
  task,
  onOpen,
  onToggle,
  grouped = false,
}: {
  task: Task
  onOpen: () => void
  onToggle: () => void
  grouped?: boolean
}) {
  return (
    <div
      className={`quest-card flex items-start gap-1 bg-white ${
        grouped
          ? "first:rounded-t-[18px] last:rounded-b-[18px]"
          : "rounded-[18px]"
      }`}
    >
      <button
        aria-label={`${task.done ? "标记为未完成" : "完成任务"}：${task.title}`}
        onClick={onToggle}
        className="flex h-[61px] w-12 shrink-0 items-center justify-center"
      >
        <span
          className={`flex h-[22px] w-[22px] items-center justify-center rounded-full border-[1.5px] ${
            task.done
              ? "border-primary bg-secondary text-primary"
              : "border-[#c9cbd0]"
          }`}
        >
          {task.done && <Check size={14} />}
        </span>
      </button>
      <button
        onClick={onOpen}
        className={`min-w-0 flex-1 py-[18px] pr-4 text-left ${
          grouped ? "border-b border-[#efeff1]" : ""
        }`}
      >
        <div className="flex items-center gap-2">
          <PixelIcon kind={task.category === "工作" ? "sword" : task.category === "健康" ? "heart" : "scroll"} className="task-category-icon" />
          <span
            className={`text-[14px] font-medium leading-6 ${
              task.done ? "text-muted-foreground line-through" : ""
            }`}
          >
            {task.title}
          </span>
        </div>
        <div className="mt-1 flex items-center gap-2 text-[11px] text-muted-foreground">
          <span>{task.category}</span>
          <span className="h-[3px] w-[3px] rounded-full bg-[#c4c6c9]" />
          <span className={task.priority === "高" ? "text-primary" : ""}>
            {task.time}
          </span>
        </div>
      </button>
    </div>
  )
}
function Workspace() {
  const navigate = useNavigate()
  const location = useLocation()
  const active =
    location.pathname === "/capture"
      ? "记录"
      : location.pathname === "/tasks"
        ? "任务"
        : location.pathname.startsWith("/task/")
          ? "详情"
          : "今天"
  const go = (screen: keyof typeof destinations) =>
    navigate(destinations[screen])
  const [tasks, setTasks] = useState(initialTasks)
  const [selected, setSelected] = useState(1)
  const [tab, setTab] = useState("今天")
  const [recording, setRecording] = useState(false)
  const [captured, setCaptured] = useState(false)
  const [thought, setThought] = useState("")
  const [editing, setEditing] = useState(false)
  const [completedAt, setCompletedAt] = useState<Record<number, number>>({})
  const [now, setNow] = useState(Date.now())
  const [showCompleted, setShowCompleted] = useState(false)
  const [reward, setReward] = useState<{ key: number; full: boolean } | null>(null)
  const energy = tasks.filter((task) => task.id <= 3 && task.done).length
  const rewardDialog = useRef<HTMLDialogElement>(null)
  useEffect(() => {
    if (energy !== 3) {
      rewardDialog.current?.close()
      return
    }
    // Let the final walk and chest-opening sequence finish before showing the reward.
    const timeout = window.setTimeout(() => {
      rewardDialog.current?.showModal()
    }, 1800)
    return () => window.clearTimeout(timeout)
  }, [energy])
  useEffect(() => {
    if (!reward) return
    const timeout = window.setTimeout(() => setReward(null), 3500)
    return () => window.clearTimeout(timeout)
  }, [reward])
  const deleteDialog = useRef<HTMLDialogElement>(null)
  const current =
    tasks.find((task) => task.id === selected) || tasks[0] || initialTasks[0]
  const archived = (task: Task) =>
    task.done && now >= (completedAt[task.id] || 0) + 6000
  const completed = tasks.filter(archived)
  const pending = tasks.filter((task) => task.done && !archived(task))
  const latestPending = [...pending].sort(
    (first, second) => completedAt[second.id] - completedAt[first.id],
  )[0]
  useEffect(() => {
    const deadlines = Object.values(completedAt)
      .map((time) => time + 6000)
      .filter((time) => time > now)
    if (!deadlines.length) return
    const timeout = window.setTimeout(
      () => setNow(Date.now()),
      Math.max(0, Math.min(...deadlines) - Date.now()),
    )
    return () => window.clearTimeout(timeout)
  }, [completedAt, now])
  const toggle = (id: number) => {
    const task = tasks.find((item) => item.id === id)
    if (!task) return
    const time = Date.now()
    if (task.id <= 3 && !task.done) {
      setReward(energy + 1 === 3 ? null : { key: time, full: false })
    } else if (task.done) {
      setReward(null)
    }
    setNow(time)
    setCompletedAt((previous) => {
      const next = { ...previous }
      if (task.done) delete next[id]
      else next[id] = time
      return next
    })
    setTasks((previous) =>
      previous.map((item) =>
        item.id === id ? { ...item, done: !item.done } : item,
      ),
    )
  }
  const deleteTask = () => {
    setTasks((previous) => previous.filter((task) => task.id !== current.id))
    setCompletedAt((previous) => {
      const next = { ...previous }
      delete next[current.id]
      return next
    })
    setEditing(false)
    deleteDialog.current?.close()
    go("任务")
  }
  const open = (id: number) => {
    setSelected(id)
    setEditing(false)
    navigate(`/task/${id}`)
  }
  const card = (task: Task, grouped = false) => (
    <TaskCard
      key={task.id}
      task={task}
      grouped={grouped}
      onToggle={() => toggle(task.id)}
      onOpen={() => open(task.id)}
    />
  )
  const completedSection = () =>
    completed.length > 0 && (
      <div className="mt-6">
        <button
          onClick={() => setShowCompleted(!showCompleted)}
          aria-expanded={showCompleted}
          className="flex w-full items-center justify-between py-3 text-[13px] text-muted-foreground"
        >
          <span>已完成 · {completed.length}</span>
          <ChevronRight
            size={15}
            className={showCompleted ? "rotate-90" : ""}
          />
        </button>
        {showCompleted && (
          <div className="overflow-hidden rounded-[18px]">
            {completed.map((task) => card(task, true))}
            <p className="bg-white px-4 pb-3 text-[11px] text-muted-foreground">
              点一下勾选，即可恢复到原来的位置。
            </p>
          </div>
        )}
      </div>
    )
  const undoNotice = () =>
    latestPending && (
      <div
        role="status"
        className="absolute inset-x-4 bottom-[100px] z-10 flex items-center gap-2 rounded-[14px] border border-border bg-white px-4 py-3 shadow-lg"
      >
        <Check size={16} className="shrink-0 text-primary" />
        <div className="min-w-0 flex-1">
          <p className="truncate text-[12px] font-medium">
            已完成：{latestPending.title}
          </p>
          <p className="mt-1 text-[10px] text-muted-foreground">
            6 秒后收起，也可以再次点勾取消
          </p>
        </div>
        <button
          onClick={() => toggle(latestPending.id)}
          className="shrink-0 px-1 py-2 text-[13px] font-medium text-primary"
        >
          撤销
        </button>
      </div>
    )
  const capture = () => {
    if (!recording) {
      setRecording(true)
      setCaptured(false)
    } else {
      setRecording(false)
      setCaptured(true)
    }
  }
  const addTask = () => {
    setTasks([
      ...tasks,
      {
        ...initialTasks[0],
        id: Date.now(),
        title: thought.trim() || "理清这个想法的下一步",
        time: "不限时间",
        priority: "中",
      },
    ])
    setThought("")
    setCaptured(false)
    go("任务")
  }
  return (
    <main className="game-workspace min-h-screen bg-background lg:px-7 lg:py-10 xl:px-12">
      <header className="mx-auto mb-9 hidden max-w-[1520px] items-end justify-between lg:flex">
        <div>
          <h1 className="text-[24px] font-semibold tracking-[1px]">
            拾念
            <span className="ml-3 text-[13px] font-normal tracking-normal text-[#87898e]">
              把现实中的小事，变成你的冒险。
            </span>
          </h1>
        </div>
        <span className="pixel-edition text-[12px] text-muted-foreground">像素冒险版 · 每一步都算数</span>
      </header>
      <div className="mx-auto grid max-w-[1520px] gap-5 lg:grid-cols-4 xl:gap-7">
        <ScreenFrame label="今天" visible={active === "今天"}>
          <div className="relative min-h-0 flex-1 overflow-y-auto px-5 pb-20 pt-5">
            <div className="adventure-panel daily-adventure">
              <div className="flex items-center gap-3">
                <div className="adventure-emblem"><PixelIcon kind="sword" /></div>
                <div className="min-w-0 flex-1">
                  <h1 className="text-[25px] font-bold">今日冒险</h1>
                  <p className="mt-1 text-xs text-muted-foreground">10月5日 星期一</p>
                </div>
                <PixelIcon kind="crown" className="pixel-gold" />
              </div>
              <PixelScene quest energy={energy} />
              <p className="adventure-caption">小小一步，也算向前。</p>
              <div className="mt-4 flex items-center justify-between text-xs">
                <span className="font-medium text-primary">任务能量</span>
                <span className="text-muted-foreground">{energy} / 3</span>
              </div>
              <div className="energy-slots" role="progressbar" aria-label="重要任务能量" aria-valuenow={energy} aria-valuemin={0} aria-valuemax={3}>
                {[0, 1, 2].map((slot) => <div key={slot} className={`energy-slot ${slot < energy ? "charged" : ""}`}><PixelIcon kind="gem" /></div>)}
              </div>
              <div className={`daily-loot ${energy === 3 ? "unlocked" : ""}`}>
                <PixelIcon kind="chest" />
                <span>{energy === 3 ? "能量集满 · 今日冒险徽章已解锁" : "完成 3 件重要的事，解锁冒险徽章"}</span>
              </div>
            </div>
            <div className="mb-3 mt-8 flex items-center justify-between">
              <h2 className="text-[17px] font-semibold">重要的事</h2>
              <span className="text-[12px] tabular-nums text-muted-foreground">
                {tasks.filter((task) => task.id <= 3 && !task.done).length}{" "}
                项待办
              </span>
            </div>
            <div className="space-y-2.5">
              {tasks
                .filter((task) => task.id <= 3 && !archived(task))
                .map((task) => card(task))}
              {!tasks.some((task) => task.id <= 3 && !archived(task)) && (
                <p className="py-4 text-[13px] text-muted-foreground">
                  重要的事都处理好了。
                </p>
              )}
            </div>
            <div className="mb-3 mt-7 flex items-center justify-between">
              <h2 className="text-[17px] font-semibold">其他待办</h2>
              <button
                onClick={() => go("任务")}
                className="flex items-center gap-0.5 text-[12px] text-primary"
              >
                全部
                <ChevronRight size={13} />
              </button>
            </div>
            <div className="overflow-hidden rounded-[18px]">
              {tasks
                .filter(
                  (task) =>
                    task.id > 3 && task.period === "今天" && !archived(task),
                )
                .map((task) => card(task, true))}
            </div>
            {completedSection()}
          </div>
          {undoNotice()}
          <button
            onClick={() => go("记录")}
            aria-label="记录一个想法"
            className={`absolute bottom-[105px] right-5 flex h-[52px] w-[52px] items-center justify-center rounded-full bg-secondary text-primary shadow-[0_5px_14px_#386e9a24] transition-transform hover:scale-105 ${
              latestPending ? "hidden" : ""
            }`}
          >
            <Mic size={24} strokeWidth={1.7} />
          </button>
          <BottomNav active="今天" go={go} />
        </ScreenFrame>
        <ScreenFrame label="记录" visible={active === "记录"}>
          <div className="flex min-h-0 flex-1 flex-col overflow-y-auto px-6 pb-6 pt-5">
            <div className="flex items-center gap-2 text-primary"><Sparkles size={18} /><h1 className="text-[17px] font-semibold">灵感收集站</h1></div>
            <PixelCaptureScene recording={recording} />
            <div className="flex flex-1 shrink-0 flex-col items-center justify-center py-6">
              <h2 className="text-[27px] font-semibold">
                {recording
                  ? "我在听。"
                  : captured
                    ? "想法，接住了。"
                    : "有什么想法？"}
              </h2>
              <p className="mt-3 text-[13px] text-muted-foreground">
                {recording
                  ? "说完后，轻点结束"
                  : captured
                    ? "确认一下，把它变成待办"
                    : "不用组织语言，想到什么就说什么。"}
              </p>
              <button
                onClick={capture}
                aria-label={recording ? "结束录音" : "开始录音"}
                className={`capture-orb mt-12 flex h-[110px] w-[110px] items-center justify-center rounded-full bg-secondary text-primary transition-transform hover:scale-105 ${
                  recording ? "animate-pulse" : ""
                }`}
              >
                {recording ? (
                  <Square size={30} fill="currentColor" />
                ) : (
                  <Mic size={39} strokeWidth={1.5} />
                )}
              </button>
              <p className="mt-5 text-[12px] text-muted-foreground">
                {recording
                  ? "正在记录"
                  : captured
                    ? "再记一个想法"
                    : "轻点开始录音"}
              </p>
              {(recording || captured) && (
                <div className="mt-6 w-full">
                  <textarea
                    aria-label="你的想法"
                    value={thought}
                    onChange={(event) => setThought(event.target.value)}
                    placeholder="把刚才的想法写在这里…"
                    className="h-24 w-full resize-none rounded-xl border border-border bg-white p-3 text-[14px] outline-primary"
                  />
                  {recording && (
                    <p className="mt-2 text-center text-[11px] text-muted-foreground">
                      预览中可使用文字记录
                    </p>
                  )}
                  {captured && (
                    <button
                      onClick={addTask}
                      className="mt-3 w-full rounded-xl bg-secondary py-3 text-[14px] font-medium text-primary"
                    >
                      生成待办
                    </button>
                  )}
                </div>
              )}
            </div>
            <div className="text-center">
              <p className="ai-caption text-[11px] text-muted-foreground">
                <PixelIcon kind="gem" />AI自动整理和分类
              </p>
            </div>
          </div>
          <BottomNav active="记录" go={go} />
        </ScreenFrame>
        <ScreenFrame label="任务" visible={active === "任务"}>
          <div className="flex min-h-0 flex-1 flex-col px-5 pt-5">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3"><PixelIcon kind="scroll" className="pixel-gold" /><h1 className="text-[31px] font-bold leading-tight">任务</h1></div>
              <button
                aria-label="添加任务"
                onClick={() => go("记录")}
                className="flex h-8 w-8 items-center justify-center rounded-full bg-white text-primary"
              >
                <Plus size={21} />
              </button>
            </div>
            <div className="mb-6 mt-6 grid shrink-0 grid-cols-3 rounded-[9px] bg-[#e6e7e9] p-[3px]">
              {["今天", "近期", "以后"].map((item) => (
                <button
                  onClick={() => setTab(item)}
                  key={item}
                  className={`rounded-[7px] py-[7px] text-[13px] font-medium transition-all ${
                    tab === item
                      ? "bg-white text-foreground shadow-sm"
                      : "text-[#777a7f]"
                  }`}
                  >
                  <PixelIcon kind={item === "今天" ? "sword" : item === "近期" ? "scroll" : "chest"} />
                  {item}
                </button>
              ))}
            </div>
            <div className="mb-3 flex items-center justify-between">
              <span className="text-[12px] text-muted-foreground">
                {
                  tasks.filter((task) => task.period === tab && !task.done)
                    .length
                }{" "}
                项待办
              </span>
            </div>
            <div className="min-h-0 overflow-y-auto pb-6">
              <div className="overflow-hidden rounded-[18px]">
                {tasks
                  .filter((task) => task.period === tab && !archived(task))
                  .map((task) => card(task, true))}
              </div>
              {!tasks.some(
                (task) => task.period === tab && !archived(task),
              ) && (
                <p className="py-6 text-center text-[13px] text-muted-foreground">
                  {tab === "今天"
                    ? "今天的待办都完成了。"
                    : "这里暂时没有待办。"}
                </p>
              )}
              <button
                onClick={() => go("记录")}
                className="mt-4 flex items-center gap-2 py-2 text-[13px] text-primary"
              >
                <Plus size={17} />
                添加待办
              </button>
              {completedSection()}
            </div>
          </div>
          {undoNotice()}
          <BottomNav active="任务" go={go} />
        </ScreenFrame>
        <ScreenFrame label="任务详情" visible={active === "详情"}>
          {tasks.length > 0 ? (
            <>
              <div className="flex shrink-0 items-center justify-between px-4 pb-2 pt-1">
                <button
                  onClick={() => go("任务")}
                  className="flex items-center gap-0.5 py-2 text-[14px] text-primary"
                >
                  <ArrowLeft size={19} />
                  任务
                </button>
                <button
                  onClick={() => setEditing(!editing)}
                  className="px-2 py-2 text-[14px] text-primary"
                >
                  {editing ? "完成" : "编辑"}
                </button>
              </div>
              <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-5">
                <div className="mt-5 flex items-start gap-3">
                  <button
                    aria-label={current.done ? "标记为未完成" : "完成任务"}
                    onClick={() => toggle(current.id)}
                    className={`mt-1.5 flex h-[25px] w-[25px] shrink-0 items-center justify-center rounded-full border-[1.5px] ${
                      current.done
                        ? "border-primary bg-secondary text-primary"
                        : "border-[#bfc5c3]"
                    }`}
                  >
                    {current.done && <Check size={16} />}
                  </button>
                  {editing ? (
                    <input
                      aria-label="任务标题"
                      value={current.title}
                      onChange={(event) =>
                        setTasks(
                          tasks.map((task) =>
                            task.id === current.id
                              ? { ...task, title: event.target.value }
                              : task,
                          ),
                        )
                      }
                      className="min-w-0 flex-1 rounded-lg border border-border bg-white p-2 text-[19px] outline-primary"
                    />
                  ) : (
                    <h1
                      className={`text-[25px] font-semibold leading-[1.45] ${
                        current.done ? "text-muted-foreground line-through" : ""
                      }`}
                    >
                      {current.title}
                    </h1>
                  )}
                </div>
                <p className="mt-5 text-[13px] leading-[1.9] text-[#82858b]">
                  {current.id === 1
                    ? "先整理一份网站改版提纲：哪些地方需要调整、保留哪些页面，以及想要的整体方向。不必一次想全，有个起点就好。"
                    : `为「${current.title}」留一点时间。从最容易的一小步开始，不必等到一切准备妥当。`}
                </p>
                <div className="mt-2 text-[10px] text-[#a6a9ad]">
                  根据你的语音整理
                </div>
                <div className="quest-properties mt-6 overflow-hidden rounded-[16px] bg-white">
                  {[
                    { icon: Tag, label: "分类", value: current.category },
                    {
                      icon: ListTodo,
                      label: "优先级",
                      value: `${current.priority}优先级`,
                    },
                    {
                      icon: CalendarDays,
                      label: "开始时间",
                      value:
                        current.time === "不限时间"
                          ? "今天，不限时间"
                          : `${current.period} ${current.time}`,
                    },
                  ].map(({ icon: Icon, label, value }, index) => (
                    <div key={label} className="flex items-center gap-3 pl-4">
                      <Icon
                        size={17}
                        strokeWidth={1.6}
                        className="text-[#979c9a]"
                      />
                      <div
                        className={`flex min-w-0 flex-1 items-center justify-between py-[15px] pr-4 text-[13px] ${
                          index < 2 ? "border-b border-[#eeeef0]" : ""
                        }`}
                      >
                        <span>{label}</span>
                        <span
                          className={
                            label === "优先级"
                              ? "text-primary"
                              : "text-[#8e9296]"
                          }
                        >
                          {value}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
                <h2 className="mb-3 mt-6 text-[13px] font-medium text-[#737a77]">
                  建议的第一步
                </h2>
                <div className="quest-hint rounded-[16px] bg-accent p-4">
                  <div className="flex items-start gap-2">
                    <ArrowUpRight
                      size={18}
                      className="mt-1 shrink-0 text-primary"
                    />
                    <p className="text-[14px] leading-6 text-accent-foreground">
                      {current.id === 1
                        ? "打开一个空白文档，写下网站最需要改善的 3 个地方。"
                        : `留出 ${current.duration}，从最容易的部分开始。`}
                    </p>
                  </div>
                  <div className="mt-3 border-t border-[#d1e3f3] pt-3 text-[11px] text-[#627f99]">
                    建议上午开始，趁思路还清晰。
                  </div>
                </div>
                <button
                  onClick={() => setEditing(!editing)}
                  className="mt-5 flex w-full items-center justify-center gap-2 rounded-xl bg-white py-3 text-[14px] font-medium text-primary"
                >
                  {editing ? <Check size={16} /> : <Pencil size={16} />}
                  {editing ? "保存修改" : "编辑任务"}
                </button>
                <button
                  onClick={() => deleteDialog.current?.showModal()}
                  className="mt-3 flex w-full items-center justify-center gap-2 rounded-xl bg-white py-3 text-[14px] text-[#b75651]"
                >
                  <Trash2 size={16} />
                  删除任务
                </button>
              </div>
              {undoNotice()}
            </>
          ) : (
            <div className="flex flex-1 flex-col items-center justify-center gap-4 text-[14px] text-muted-foreground">
              <p>还没有任务</p>
              <button onClick={() => go("记录")} className="text-primary">
                记录一个想法
              </button>
            </div>
          )}
          <HomeIndicator />
        </ScreenFrame>
      </div>
      {reward && (
        <div key={reward.key} className={`pixel-reward ${reward.full ? "grand-reward" : ""}`} role="status" aria-live="polite">
          <div className="reward-sparks" aria-hidden="true">{Array.from({ length: 12 }, (_, index) => <i key={index} />)}</div>
          <PixelIcon kind={reward.full ? "crown" : "gem"} />
          <div><p>{reward.full ? "今日冒险完成！" : "任务完成 · 能量 +1"}</p><span>{reward.full ? "三格能量集满，获得冒险徽章" : "又向前迈出了一小步"}</span></div>
        </div>
      )}
      <dialog
        ref={rewardDialog}
        aria-labelledby="adventure-reward-title"
        className="pixel-dialog adventure-reward-dialog fixed inset-0 m-auto bg-card text-center text-foreground"
      >
        <div className="reward-badge-art" aria-hidden="true">
          <div className="reward-sparks">{Array.from({ length: 12 }, (_, index) => <i key={index} />)}</div>
          <PixelIcon kind="crown" />
        </div>
        <p className="reward-eyebrow">宝箱已开启</p>
        <h2 id="adventure-reward-title">今日冒险完成！</h2>
        <p className="reward-description">三件重要的事，全部完成。<br />每一小步，都值得被认真庆祝。</p>
        <div className="earned-badge"><PixelIcon kind="gem" /><span>获得「三步冒险家」徽章</span></div>
        <button
          autoFocus
          onClick={() => rewardDialog.current?.close()}
          className="reward-dismiss"
        >
          收下奖励
        </button>
        <p className="reward-footnote">关闭后留在当前页面，任务仍可撤销或恢复。</p>
      </dialog>
      <dialog
        ref={deleteDialog}
        aria-labelledby="delete-title"
        className="pixel-dialog fixed inset-0 m-auto w-[290px] bg-card p-0 text-center text-foreground shadow-xl backdrop:bg-black/30"
      >
        <div className="px-6 pb-5 pt-6">
          <h2 id="delete-title" className="text-[17px] font-semibold">
            删除这项任务？
          </h2>
          <p className="mt-2 text-[13px] leading-6 text-muted-foreground">
            「{current.title}」将被删除，此操作无法撤销。
          </p>
        </div>
        <div className="flex border-t border-border">
          <button
            autoFocus
            onClick={() => deleteDialog.current?.close()}
            className="flex-1 border-r border-border py-3.5 text-[15px] font-semibold text-primary"
          >
            取消
          </button>
          <button
            onClick={deleteTask}
            className="flex-1 py-3.5 text-[15px] text-[#b75651]"
          >
            删除
          </button>
        </div>
      </dialog>
    </main>
  )
}
const router = createBrowserRouter([{ path: "*", Component: Workspace }])
export default function App() {
  return <RouterProvider router={router} />
}
