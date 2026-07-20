import { useEffect, useMemo, useState, type ReactNode, type FormEvent } from "react";
import {
  Activity,
  AlertCircle,
  Bell,
  Building2,
  CheckCircle2,
  ChevronDown,
  ChevronLeft,
  ClipboardList,
  Database,
  Eye,
  Home,
  LogOut,
  PawPrint,
  Pencil,
  Plus,
  RefreshCw,
  Search,
  Server,
  Trash2,
  UserCheck,
  Users,
  Wifi,
  WifiOff,
  X,
  XCircle,
} from "lucide-react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

// ─────────────────────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────────────────────
type Screen =
  | "dashboard"
  | "sedes"
  | "clientes"
  | "mascotas"
  | "empleados"
  | "servicios"
  | "historial"
  | "sincronizacion";

type NodeKey = "cumbaya" | "inaquito";

interface NodeInfo {
  key: NodeKey;
  code: string;
  name: string;
  location: string;
  database: string;
  server: string;
}

interface UserInfo {
  username: string;
  display_name: string;
  role: string;
  allowed_nodes: NodeKey[];
  default_node: NodeKey;
}

interface FieldDef {
  name: string;
  label: string;
  input_type: string;
  required: boolean;
  max_length: number | null;
  step: string | null;
  help_text: string | null;
  options_source: string | null;
  readonly: boolean;
}

interface EntityDef {
  key: string;
  singular: string;
  plural: string;
  description: string;
  primary_key: string;
  storage_strategy: string;
  routing_label: string;
  fields: FieldDef[];
  list_columns: [string, string][];
}

type EntitiesMap = Record<string, EntityDef>;
type RowRecord = Record<string, string | number | null>;

interface SessionState {
  authenticated: boolean;
  user?: UserInfo;
  active_node?: NodeInfo;
  nodes?: Record<string, NodeInfo>;
  entities?: EntitiesMap;
  csrf_token?: string;
}

interface DashboardData {
  node: NodeInfo;
  counts: Record<string, number>;
  current_status: { ok: boolean; message: string };
  node_statuses: Record<string, { ok: boolean; message: string; node: NodeInfo }>;
}

interface ReplicationItem {
  entity: string;
  cumbaya_count: number;
  inaquito_count: number;
  missing_cumbaya: string[];
  missing_inaquito: string[];
  ok: boolean;
}

interface ReplicationData {
  items: ReplicationItem[];
  nodes: Record<string, { ok: boolean; message: string; node: NodeInfo }>;
}

// ─────────────────────────────────────────────────────────────────────────────
// API helpers
// ─────────────────────────────────────────────────────────────────────────────
async function api<T>(url: string, options: RequestInit = {}, csrfToken?: string): Promise<T> {
  const headers = new Headers(options.headers || {});
  if (!(options.body instanceof FormData)) {
    headers.set("Content-Type", "application/json");
  }
  headers.set("Accept", "application/json");
  if (csrfToken && ["POST", "PUT", "PATCH", "DELETE"].includes((options.method || "GET").toUpperCase())) {
    headers.set("X-CSRF-Token", csrfToken);
  }

  const response = await fetch(url, {
    ...options,
    headers,
    credentials: "include",
  });

  const contentType = response.headers.get("content-type") || "";
  const payload = contentType.includes("application/json") ? await response.json() : null;

  if (!response.ok) {
    const error = new Error(payload?.message || "Ocurrió un error en la solicitud.") as Error & {
      status?: number;
      errors?: Record<string, string>;
    };
    error.status = response.status;
    error.errors = payload?.errors || {};
    throw error;
  }

  return payload as T;
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility components
// ─────────────────────────────────────────────────────────────────────────────
function StatCard({
  label,
  value,
  icon,
  color,
  sub,
}: {
  label: string;
  value: string | number;
  icon: ReactNode;
  color: string;
  sub?: string;
}) {
  return (
    <div className="bg-card rounded-xl border border-border p-4 flex items-start gap-3 shadow-sm">
      <div className={`w-10 h-10 rounded-lg flex items-center justify-center shrink-0 ${color}`}>{icon}</div>
      <div className="min-w-0">
        <p className="text-2xl font-bold text-foreground leading-none">{value}</p>
        <p className="text-xs text-muted-foreground mt-0.5">{label}</p>
        {sub && <p className="text-xs text-muted-foreground/70 mt-0.5">{sub}</p>}
      </div>
    </div>
  );
}

function Alert({
  type,
  message,
  onClose,
}: {
  type: "success" | "warning" | "error" | "info";
  message: string;
  onClose?: () => void;
}) {
  const styles = {
    success: "bg-green-50 border-green-300 text-green-800",
    warning: "bg-amber-50 border-amber-300 text-amber-800",
    error: "bg-red-50 border-red-300 text-red-800",
    info: "bg-blue-50 border-blue-300 text-blue-800",
  }[type];
  const icon = {
    success: <CheckCircle2 size={16} className="text-green-600 shrink-0" />,
    warning: <AlertCircle size={16} className="text-amber-600 shrink-0" />,
    error: <XCircle size={16} className="text-red-600 shrink-0" />,
    info: <Bell size={16} className="text-blue-600 shrink-0" />,
  }[type];

  return (
    <div className={`flex items-start gap-2 px-3 py-2.5 rounded-md border text-sm ${styles}`}>
      {icon}
      <span className="flex-1">{message}</span>
      {onClose && (
        <button onClick={onClose} className="ml-auto opacity-60 hover:opacity-100">
          <X size={14} />
        </button>
      )}
    </div>
  );
}

function NodeBadge({ node }: { node: NodeInfo }) {
  const isCumbaya = node.key === "cumbaya";
  return (
    <span
      className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-mono font-medium ${
        isCumbaya ? "bg-blue-100 text-blue-700" : "bg-violet-100 text-violet-700"
      }`}
    >
      <Server size={10} />
      {node.location} {node.code}
    </span>
  );
}

function SearchBar({ value, onChange, placeholder = "Buscar…" }: { value: string; onChange: (v: string) => void; placeholder?: string }) {
  return (
    <div className="relative">
      <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="pl-8 pr-3 py-2 rounded-lg border border-border bg-input-background text-sm outline-none focus:ring-2 focus:ring-ring/30 focus:border-ring transition w-64"
      />
    </div>
  );
}

function Modal({
  title,
  children,
  onClose,
  onConfirm,
  confirmLabel = "Guardar",
  busy = false,
  width = "max-w-3xl",
  danger = false,
}: {
  title: string;
  children: ReactNode;
  onClose: () => void;
  onConfirm?: () => void;
  confirmLabel?: string;
  busy?: boolean;
  width?: string;
  danger?: boolean;
}) {
  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4">
      <div className={`bg-card rounded-xl shadow-2xl w-full ${width} border border-border max-h-[92vh] overflow-hidden`}>
        <div className="flex items-center justify-between px-5 py-4 border-b border-border">
          <h3 className="font-semibold text-foreground text-sm">{title}</h3>
          <button onClick={onClose} className="text-muted-foreground hover:text-foreground transition-colors">
            <X size={16} />
          </button>
        </div>
        <div className="px-5 py-4 overflow-y-auto max-h-[calc(92vh-76px)]">{children}</div>
        {onConfirm && (
          <div className="flex justify-end gap-2 px-5 pb-4">
            <button onClick={onClose} className="px-3 py-1.5 rounded-lg border border-border text-sm text-foreground hover:bg-muted transition-colors">
              Cancelar
            </button>
            <button
              disabled={busy}
              onClick={onConfirm}
              className={`px-3 py-1.5 rounded-lg text-sm text-white transition-colors disabled:opacity-60 ${
                danger ? "bg-red-600 hover:bg-red-700" : "bg-accent hover:bg-accent/90"
              }`}
            >
              {busy ? "Procesando..." : confirmLabel}
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

function formatValue(value: any): string {
  if (value === null || value === undefined || value === "") return "—";
  return String(value);
}

function normalizeRowText(row: RowRecord): string {
  return Object.values(row)
    .map((v) => String(v ?? "").toLowerCase())
    .join(" ");
}

function defaultValueForField(field: FieldDef, activeNode?: NodeInfo): string {
  if (field.name === "Codigo_sede" && activeNode) return activeNode.code;
  if (field.input_type === "date") return new Date().toISOString().slice(0, 10);
  return "";
}

function strategyName(strategy: string): string {
  const names: Record<string, string> = {
    horizontal_vpa: "Vista particionada",
    merge_replica_local: "Réplica de mezcla",
    publisher_local: "Tabla publicadora",
    replicated_read_only: "Réplica de lectura",
  };
  return names[strategy] || "Tabla local";
}

// ─────────────────────────────────────────────────────────────────────────────
// Login
// ─────────────────────────────────────────────────────────────────────────────
function LoginScreen({
  onLogin,
}: {
  onLogin: (username: string, password: string) => Promise<void>;
}) {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      await onLogin(username, password);
    } catch (err: any) {
      setError(err.message || "No fue posible iniciar sesión.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-screen">
      <div className="login-shell">
        <header className="login-brand">
          <div className="login-brand-icon" aria-hidden="true"><PawPrint size={38} strokeWidth={2.4} /></div>
          <h1>PetLovers</h1>
          <p>Gestión veterinaria</p>
        </header>

        <main className="login-form-panel">
          <p className="login-welcome">Acceso al sistema</p>
          {error && <div className="mb-4"><Alert type="error" message={error} onClose={() => setError(null)} /></div>}

          <form onSubmit={submit} className="space-y-4">
            <div>
              <label htmlFor="username" className="login-field-label">Usuario</label>
              <input id="username" value={username} onChange={(e) => setUsername(e.target.value)} autoComplete="username" required className="login-input" />
            </div>
            <div>
              <label htmlFor="password" className="login-field-label">Contraseña</label>
              <input id="password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} autoComplete="current-password" required className="login-input" />
            </div>
            <button type="submit" disabled={loading} className="login-submit">
              <Wifi size={17} /> {loading ? "Validando..." : "Iniciar sesión"}
            </button>
          </form>
          <p className="login-security-note">Sistema protegido · Solo personal autorizado</p>
        </main>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared layout components
// ─────────────────────────────────────────────────────────────────────────────
function Sidebar({
  screen,
  onNav,
  onLogout,
}: {
  screen: Screen;
  onNav: (screen: Screen) => void;
  onLogout: () => void;
}) {
  const items: { key: Screen; label: string; icon: ReactNode }[] = [
    { key: "dashboard", label: "Dashboard", icon: <Home size={16} /> },
    { key: "sedes", label: "Sedes", icon: <Building2 size={16} /> },
    { key: "clientes", label: "Clientes", icon: <Users size={16} /> },
    { key: "mascotas", label: "Mascotas", icon: <PawPrint size={16} /> },
    { key: "empleados", label: "Empleados", icon: <UserCheck size={16} /> },
    { key: "servicios", label: "Servicios", icon: <Activity size={16} /> },
    { key: "historial", label: "Historial", icon: <ClipboardList size={16} /> },
  ];

  return (
    <aside className="w-[270px] bg-card border-r border-border flex flex-col">
      <div className="px-5 py-5 border-b border-border">
        <div className="inline-flex items-center gap-2 px-2.5 py-1 rounded-full bg-accent/10 text-accent text-xs font-semibold mb-3">
          <Database size={12} /> PetLovers DM
        </div>
        <h1 className="text-lg font-bold text-foreground">Distributed Manager</h1>
        <p className="text-xs text-muted-foreground mt-1">Clínica veterinaria · Gestión de nodos</p>
      </div>

      <nav className="flex-1 p-3 space-y-1 overflow-y-auto">
        {items.map((item) => {
          const active = item.key === screen;
          return (
            <button
              key={item.key}
              onClick={() => onNav(item.key)}
              className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm transition-colors ${
                active ? "bg-accent text-white shadow-sm" : "text-foreground hover:bg-muted"
              }`}
            >
              {item.icon}
              <span>{item.label}</span>
            </button>
          );
        })}
      </nav>

      <div className="p-3 border-t border-border">
        <button onClick={onLogout} className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm text-red-600 hover:bg-red-50 transition-colors">
          <LogOut size={16} /> Cerrar sesión
        </button>
      </div>
    </aside>
  );
}

function TopBar({
  user,
  activeNode,
}: {
  user: UserInfo;
  activeNode: NodeInfo;
}) {
  return (
    <header className="h-16 border-b border-border bg-background/90 backdrop-blur-sm px-5 flex items-center gap-4 shrink-0">
      <div>
        <p className="text-sm font-semibold text-foreground">{activeNode.name}</p>
        <p className="text-xs text-muted-foreground">{activeNode.database} · {activeNode.server || "No configurado"}</p>
      </div>

      <div className="ml-auto flex items-center gap-3">
        <div className="rounded-xl border border-green-200 bg-green-50 px-3 py-2 text-xs font-medium text-green-700">
          Conexión SQL local · sede {activeNode.code}
        </div>

        <div className="rounded-xl border border-border bg-card px-3 py-2 text-right">
          <p className="text-sm font-semibold text-foreground">{user.display_name}</p>
          <p className="text-xs text-muted-foreground">{user.role}</p>
        </div>
      </div>
    </header>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard screen
// ─────────────────────────────────────────────────────────────────────────────
function DashboardScreen({ data }: { data: DashboardData | null }) {
  if (!data) {
    return <ScreenLoading label="Cargando dashboard..." />;
  }

  const chartData = Object.entries(data.counts).map(([name, value]) => ({ name, value }));
  const pieColors = ["#2B80D0", "#16A34A", "#D97706", "#7C3AED", "#EF4444", "#0EA5E9"];
  const nodeStates = Object.values(data.node_statuses);

  return (
    <div className="p-5 space-y-5 overflow-y-auto h-full">
      <div>
        <h2 className="text-lg font-semibold text-foreground">Dashboard operativo</h2>
        <p className="text-sm text-muted-foreground mt-0.5">Resumen en tiempo real del nodo activo y del estado de conectividad.</p>
      </div>

      <div className="grid grid-cols-2 xl:grid-cols-6 gap-3">
        {chartData.map((item, index) => {
          const icons = [<Building2 size={18} className="text-blue-600" />, <Users size={18} className="text-green-600" />, <PawPrint size={18} className="text-violet-600" />, <UserCheck size={18} className="text-amber-600" />, <Activity size={18} className="text-cyan-600" />, <ClipboardList size={18} className="text-red-600" />];
          const colors = ["bg-blue-100", "bg-green-100", "bg-violet-100", "bg-amber-100", "bg-cyan-100", "bg-red-100"];
          return <StatCard key={item.name} label={item.name} value={item.value} icon={icons[index] || icons[0]} color={colors[index] || colors[0]} />;
        })}
      </div>

      <div className="grid lg:grid-cols-2 gap-4">
        <div className="bg-card rounded-xl border border-border p-4 shadow-sm">
          <h3 className="text-sm font-semibold text-foreground mb-3">Distribución de registros</h3>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(148,163,184,0.25)" />
                <XAxis dataKey="name" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} allowDecimals={false} />
                <Tooltip />
                <Bar dataKey="value" radius={[6, 6, 0, 0]} fill="#2B80D0" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="bg-card rounded-xl border border-border p-4 shadow-sm">
          <h3 className="text-sm font-semibold text-foreground mb-3">Composición del nodo activo</h3>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={chartData} dataKey="value" nameKey="name" innerRadius={56} outerRadius={90} paddingAngle={2}>
                  {chartData.map((entry, index) => (
                    <Cell key={entry.name} fill={pieColors[index % pieColors.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      <div className="grid lg:grid-cols-3 gap-4">
        <div className="bg-card rounded-xl border border-border p-4 shadow-sm lg:col-span-2">
          <h3 className="text-sm font-semibold text-foreground mb-3">Estado de conexión</h3>
          <div className="space-y-3">
            <div className={`p-3 rounded-xl border ${data.current_status.ok ? "bg-green-50 border-green-200" : "bg-red-50 border-red-200"}`}>
              <div className="flex items-center gap-2 text-sm font-medium">
                {data.current_status.ok ? <Wifi size={16} className="text-green-600" /> : <WifiOff size={16} className="text-red-600" />}
                Nodo activo
              </div>
              <p className="text-xs text-muted-foreground mt-1">{data.current_status.message}</p>
            </div>
            {nodeStates.map((status) => (
              <div key={status.node.key} className="flex items-center justify-between px-3 py-3 rounded-xl border border-border bg-muted/20 text-sm">
                <div>
                  <p className="font-medium text-foreground">{status.node.name}</p>
                  <p className="text-xs text-muted-foreground">{status.node.database}</p>
                </div>
                <div className="flex items-center gap-2">
                  <span className={`text-xs font-medium ${status.ok ? "text-green-700" : "text-red-700"}`}>{status.ok ? "Disponible" : "Con problemas"}</span>
                  {status.ok ? <Wifi size={15} className="text-green-600" /> : <WifiOff size={15} className="text-red-600" />}
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-card rounded-xl border border-border p-4 shadow-sm">
          <h3 className="text-sm font-semibold text-foreground mb-3">Información del nodo</h3>
          <div className="space-y-3 text-sm">
            <div>
              <p className="text-xs text-muted-foreground uppercase tracking-wide">Nombre</p>
              <p className="font-medium text-foreground mt-1">{data.node.name}</p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground uppercase tracking-wide">Ubicación</p>
              <p className="font-medium text-foreground mt-1">{data.node.location}</p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground uppercase tracking-wide">Base de datos</p>
              <p className="font-medium text-foreground mt-1">{data.node.database}</p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground uppercase tracking-wide">Servidor</p>
              <p className="font-medium text-foreground mt-1 break-all">{data.node.server || "Pendiente de configurar"}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic entity screen
// ─────────────────────────────────────────────────────────────────────────────
function EntityScreen({
  entity,
  activeNode,
  csrfToken,
  emphasizeCreate = false,
  onNotify,
}: {
  entity: EntityDef;
  activeNode: NodeInfo;
  csrfToken: string;
  emphasizeCreate?: boolean;
  onNotify: (type: "success" | "error" | "warning" | "info", message: string) => void;
}) {
  const [rows, setRows] = useState<RowRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [siteFilter, setSiteFilter] = useState<"all" | "001" | "002">("all");
  const [refreshIndex, setRefreshIndex] = useState(0);
  const [modalMode, setModalMode] = useState<"create" | "edit" | null>(emphasizeCreate ? "create" : null);
  const [editOriginalKey, setEditOriginalKey] = useState("");
  const [formValues, setFormValues] = useState<Record<string, string>>({});
  const [formErrors, setFormErrors] = useState<Record<string, string>>({});
  const [formOptions, setFormOptions] = useState<Record<string, { value: string; label: string }[]>>({});
  const [saving, setSaving] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<RowRecord | null>(null);

  const primaryKey = entity.primary_key;

  async function loadRows() {
    setLoading(true);
    try {
      const data = await api<{ rows: RowRecord[] }>(`/api/entities/${entity.key}`);
      setRows(data.rows);
    } catch (err: any) {
      onNotify("error", err.message || `No se pudo consultar ${entity.plural}.`);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadRows();
  }, [entity.key, activeNode.key, refreshIndex]);

  useEffect(() => {
    if (emphasizeCreate) {
      startCreate();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [entity.key, activeNode.key]);

  const hasSiteField = entity.fields.some((field) => field.name === "Codigo_sede");
  const filteredRows = useMemo(
    () => rows.filter((row) => {
      const matchesSearch = normalizeRowText(row).includes(search.toLowerCase());
      const matchesSite = siteFilter === "all" || String(row.Codigo_sede || "").trim() === siteFilter;
      return matchesSearch && matchesSite;
    }),
    [rows, search, siteFilter],
  );

  useEffect(() => {
    setSiteFilter("all");
  }, [entity.key]);

  async function loadOptions(site?: string) {
    const fieldOptions: Record<string, { value: string; label: string }[]> = {};
    for (const field of entity.fields) {
      if (field.options_source) {
        const filter = ["servicios", "empleados"].includes(field.options_source) && site
          ? `?site=${encodeURIComponent(site)}`
          : "";
        const result = await api<{ items: { value: string; label: string }[] }>(`/api/options/${field.options_source}${filter}`);
        fieldOptions[field.name] = result.items;
      }
    }
    setFormOptions(fieldOptions);
  }

  function startCreate() {
    const values: Record<string, string> = {};
    entity.fields.forEach((field) => {
      values[field.name] = defaultValueForField(field, activeNode);
    });
    setEditOriginalKey("");
    setFormValues(values);
    setFormErrors({});
    setFormOptions({});
    loadOptions(activeNode.code).catch(() => undefined);
    setModalMode("create");
  }

  async function startEdit(row: RowRecord) {
    const key = String(row._key || row[primaryKey]);
    try {
      const data = await api<{ row: RowRecord }>(`/api/entities/${entity.key}/${encodeURIComponent(key)}`);
      const values: Record<string, string> = {};
      entity.fields.forEach((field) => {
        values[field.name] = String(data.row[field.name] ?? "");
      });
      setEditOriginalKey(key);
      setFormValues(values);
      setFormErrors({});
      await loadOptions(String(data.row.Codigo_sede || activeNode.code));
      setModalMode("edit");
    } catch (err: any) {
      onNotify("error", err.message || `No se pudo cargar ${entity.singular}.`);
    }
  }

  async function submitForm() {
    setSaving(true);
    setFormErrors({});
    try {
      if (modalMode === "create") {
        await api(`/api/entities/${entity.key}`, { method: "POST", body: JSON.stringify(formValues) }, csrfToken);
        onNotify("success", `${entity.singular.charAt(0).toUpperCase() + entity.singular.slice(1)} creado correctamente.`);
      } else if (modalMode === "edit") {
        const keyForUpdate = editOriginalKey || formValues[primaryKey];
        await api(`/api/entities/${entity.key}/${encodeURIComponent(keyForUpdate)}`, { method: "PUT", body: JSON.stringify(formValues) }, csrfToken);
        onNotify("success", `${entity.singular.charAt(0).toUpperCase() + entity.singular.slice(1)} actualizado correctamente.`);
      }
      setModalMode(null);
      setEditOriginalKey("");
      setRefreshIndex((value) => value + 1);
    } catch (err: any) {
      if (err.errors) setFormErrors(err.errors);
      onNotify("error", err.message || "No se pudo guardar el registro.");
    } finally {
      setSaving(false);
    }
  }

  async function confirmDelete() {
    if (!deleteTarget) return;
    setSaving(true);
    try {
      const key = String(deleteTarget._key || deleteTarget[primaryKey]);
      await api(`/api/entities/${entity.key}/${encodeURIComponent(key)}`, { method: "DELETE" }, csrfToken);
      onNotify("success", `${entity.singular.charAt(0).toUpperCase() + entity.singular.slice(1)} eliminado correctamente.`);
      setDeleteTarget(null);
      setRefreshIndex((value) => value + 1);
    } catch (err: any) {
      onNotify("error", err.message || "No se pudo eliminar el registro.");
    } finally {
      setSaving(false);
    }
  }

  function closeFormModal() {
    setModalMode(null);
    setEditOriginalKey("");
  }

  return (
    <div className="p-5 space-y-4 overflow-y-auto h-full">
      <div className="flex items-start gap-4">
        <div>
          <h2 className="text-lg font-semibold text-foreground">{entity.plural}</h2>
          <p className="text-sm text-muted-foreground mt-0.5">{entity.description}</p>
        </div>
        <div className="ml-auto flex items-center gap-2">
          {hasSiteField && (
            <select
              value={siteFilter}
              onChange={(event) => setSiteFilter(event.target.value as "all" | "001" | "002")}
              aria-label="Filtrar por nodo"
              className="px-3 py-2 rounded-xl border border-border bg-input-background text-sm text-foreground outline-none focus:ring-2 focus:ring-ring/30"
            >
              <option value="all">Todos los nodos</option>
              <option value="001">Cumbayá · 001</option>
              <option value="002">Iñaquito · 002</option>
            </select>
          )}
          <SearchBar value={search} onChange={setSearch} placeholder={`Buscar ${entity.singular}...`} />
          <button onClick={() => setRefreshIndex((value) => value + 1)} className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-border text-sm hover:bg-muted transition-colors">
            <RefreshCw size={14} /> Recargar
          </button>
          <button onClick={startCreate} className="inline-flex items-center gap-2 px-3 py-2 rounded-xl bg-accent text-white text-sm hover:bg-accent/90 transition-colors">
            <Plus size={14} /> Nuevo
          </button>
        </div>
      </div>

      <div className="grid md:grid-cols-4 gap-3">
        <StatCard label="Nodo activo" value={activeNode.location} icon={<Server size={18} className="text-blue-600" />} color="bg-blue-100" sub={activeNode.code} />
        <StatCard label="Enrutamiento" value={strategyName(entity.storage_strategy)} icon={<Database size={18} className="text-violet-600" />} color="bg-violet-100" sub={entity.routing_label} />
        <StatCard label="Registros" value={rows.length} icon={<CheckCircle2 size={18} className="text-green-600" />} color="bg-green-100" />
        <StatCard label="Coincidencias" value={filteredRows.length} icon={<Search size={18} className="text-amber-600" />} color="bg-amber-100" />
      </div>

      <div className="bg-card rounded-xl border border-border shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border bg-muted/30">
                {entity.list_columns.map(([column, label]) => (
                  <th key={column} className="text-left px-4 py-3 text-muted-foreground font-medium whitespace-nowrap">
                    {label}
                  </th>
                ))}
                <th className="text-left px-4 py-3 text-muted-foreground font-medium">Acciones</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={entity.list_columns.length + 1} className="px-4 py-10 text-center text-muted-foreground">
                    Cargando datos...
                  </td>
                </tr>
              ) : filteredRows.length === 0 ? (
                <tr>
                  <td colSpan={entity.list_columns.length + 1} className="px-4 py-10 text-center text-muted-foreground">
                    No se encontraron registros.
                  </td>
                </tr>
              ) : (
                filteredRows.map((row) => (
                  <tr key={String(row._key || row[primaryKey])} className="border-b border-border/50 hover:bg-muted/20 transition-colors">
                    {entity.list_columns.map(([column]) => (
                      <td key={column} className="px-4 py-3 align-top">
                        {formatValue(row[column])}
                      </td>
                    ))}
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-1.5">
                        <button onClick={() => startEdit(row)} className="p-1.5 rounded hover:bg-blue-50 text-blue-600 transition-colors" title="Editar">
                          <Pencil size={14} />
                        </button>
                        <button onClick={() => startEdit(row)} className="p-1.5 rounded hover:bg-emerald-50 text-emerald-600 transition-colors" title="Ver detalle">
                          <Eye size={14} />
                        </button>
                        <button onClick={() => setDeleteTarget(row)} className="p-1.5 rounded hover:bg-red-50 text-red-600 transition-colors" title="Eliminar">
                          <Trash2 size={14} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {modalMode && (
        <Modal
          title={`${modalMode === "create" ? "Crear" : "Editar"} ${entity.singular}`}
          onClose={closeFormModal}
          onConfirm={submitForm}
          confirmLabel={modalMode === "create" ? "Crear registro" : "Guardar cambios"}
          busy={saving}
        >
          <div className="grid md:grid-cols-2 gap-4">
            {entity.fields.map((field) => (
              <div key={field.name} className="flex flex-col gap-1">
                <label className="text-xs font-medium text-muted-foreground uppercase tracking-wide">{field.label}</label>
                {(() => {
                  const fieldReadonly = field.readonly || (modalMode === "edit" && (field.name === primaryKey || field.name === "Codigo_sede"));
                  return field.options_source ? (
                  <div className="relative">
                    <select
                      value={formValues[field.name] || ""}
                      onChange={(e) => {
                        const value = e.target.value;
                        setFormValues((prev) => ({ ...prev, [field.name]: value }));
                        if (field.name === "Codigo_sede") {
                          loadOptions(value).catch(() => undefined);
                        }
                      }}
                      disabled={fieldReadonly}
                      className="w-full px-3 py-2 rounded-lg border border-border bg-input-background text-sm text-foreground outline-none focus:ring-2 focus:ring-ring/30 appearance-none disabled:opacity-60"
                    >
                      <option value="">Seleccione...</option>
                      {(formOptions[field.name] || []).map((option) => (
                        <option key={`${option.value}-${option.label}`} value={option.value}>
                          {option.label}
                        </option>
                      ))}
                    </select>
                    <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground pointer-events-none" />
                  </div>
                  ) : (
                  <input
                    type={field.input_type || "text"}
                    value={formValues[field.name] || ""}
                    onChange={(e) => setFormValues((prev) => ({ ...prev, [field.name]: e.target.value }))}
                    disabled={fieldReadonly}
                    maxLength={field.max_length || undefined}
                    step={field.step || undefined}
                    className="px-3 py-2 rounded-lg border border-border bg-input-background text-sm text-foreground outline-none focus:ring-2 focus:ring-ring/30 disabled:opacity-60"
                  />
                  );
                })()}
                {field.help_text && <span className="text-xs text-muted-foreground">{field.help_text}</span>}
                {formErrors[field.name] && <span className="text-xs text-red-600">{formErrors[field.name]}</span>}
              </div>
            ))}
          </div>
        </Modal>
      )}

      {deleteTarget && (
        <Modal title={`Eliminar ${entity.singular}`} onClose={() => setDeleteTarget(null)} onConfirm={confirmDelete} confirmLabel="Eliminar" danger busy={saving} width="max-w-md">
          <p className="text-sm text-foreground/80">
            Se eliminará el registro con clave <strong>{String(deleteTarget[primaryKey])}</strong>. Esta operación no se puede deshacer.
          </p>
        </Modal>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Replication screen
// ─────────────────────────────────────────────────────────────────────────────
function ReplicationScreen({ onNotify }: { onNotify: (type: "success" | "error" | "warning" | "info", message: string) => void }) {
  const [data, setData] = useState<ReplicationData | null>(null);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<ReplicationItem | null>(null);

  async function loadData() {
    setLoading(true);
    try {
      const payload = await api<ReplicationData>("/api/replication");
      setData(payload);
    } catch (err: any) {
      onNotify("error", err.message || "No se pudo consultar el estado de sincronización.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadData();
  }, []);

  if (loading) {
    return <ScreenLoading label="Comprobando replicación..." />;
  }

  if (!data) {
    return <EmptyState title="Sin datos de replicación" description="No fue posible obtener la comparación entre Cumbayá e Iñaquito." />;
  }

  const totalOk = data.items.filter((item) => item.ok).length;
  const totalIssues = data.items.length - totalOk;

  return (
    <div className="p-5 space-y-5 overflow-y-auto h-full">
      <div className="flex items-start gap-3">
        <div>
          <h2 className="text-lg font-semibold text-foreground">Estado de sincronización</h2>
          <p className="text-sm text-muted-foreground mt-0.5">Validación funcional de las tablas replicadas: Sede, Cliente y Mascota.</p>
        </div>
        <button onClick={loadData} className="ml-auto inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-border text-sm hover:bg-muted transition-colors">
          <RefreshCw size={14} /> Actualizar
        </button>
      </div>

      <div className="grid md:grid-cols-4 gap-3">
        <StatCard label="Entidades sincronizadas" value={totalOk} icon={<CheckCircle2 size={18} className="text-green-600" />} color="bg-green-100" />
        <StatCard label="Entidades con diferencias" value={totalIssues} icon={<AlertCircle size={18} className="text-amber-600" />} color="bg-amber-100" />
        {Object.values(data.nodes).map((nodeStatus) => (
          <StatCard
            key={nodeStatus.node.key}
            label={nodeStatus.node.location}
            value={nodeStatus.ok ? "Activo" : "Error"}
            icon={nodeStatus.ok ? <Wifi size={18} className="text-blue-600" /> : <WifiOff size={18} className="text-red-600" />}
            color={nodeStatus.ok ? "bg-blue-100" : "bg-red-100"}
            sub={nodeStatus.node.database}
          />
        ))}
      </div>

      <div className="bg-card rounded-xl border border-border shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border bg-muted/30">
                {[
                  "Entidad",
                  "Cumbayá",
                  "Iñaquito",
                  "Faltantes en Cumbayá",
                  "Faltantes en Iñaquito",
                  "Estado",
                  "Acciones",
                ].map((label) => (
                  <th key={label} className="text-left px-4 py-3 text-muted-foreground font-medium">
                    {label}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {data.items.map((item) => (
                <tr key={item.entity} className="border-b border-border/50 hover:bg-muted/20 transition-colors">
                  <td className="px-4 py-3 font-medium text-foreground">{item.entity}</td>
                  <td className="px-4 py-3">{item.cumbaya_count}</td>
                  <td className="px-4 py-3">{item.inaquito_count}</td>
                  <td className="px-4 py-3">{item.missing_cumbaya.length}</td>
                  <td className="px-4 py-3">{item.missing_inaquito.length}</td>
                  <td className="px-4 py-3">
                    {item.ok ? (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-700">
                        <CheckCircle2 size={11} /> Sincronizado
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-700">
                        <AlertCircle size={11} /> Revisar
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    <button onClick={() => setSelected(item)} className="p-1.5 rounded hover:bg-blue-50 text-blue-600 transition-colors">
                      <Eye size={14} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {selected && (
        <Modal title={`Detalle de replicación · ${selected.entity}`} onClose={() => setSelected(null)} width="max-w-2xl">
          <div className="grid md:grid-cols-2 gap-4">
            <div className="rounded-xl border border-border p-4 bg-muted/15">
              <h4 className="font-semibold text-sm mb-3">Nodo Cumbayá</h4>
              <p className="text-sm text-foreground">Registros: <strong>{selected.cumbaya_count}</strong></p>
              <p className="text-xs text-muted-foreground mt-3 mb-2">Claves faltantes en Cumbayá</p>
              <div className="rounded-lg bg-card border border-border p-3 text-xs min-h-24">
                {selected.missing_cumbaya.length ? selected.missing_cumbaya.join(", ") : "Sin diferencias"}
              </div>
            </div>
            <div className="rounded-xl border border-border p-4 bg-muted/15">
              <h4 className="font-semibold text-sm mb-3">Nodo Iñaquito</h4>
              <p className="text-sm text-foreground">Registros: <strong>{selected.inaquito_count}</strong></p>
              <p className="text-xs text-muted-foreground mt-3 mb-2">Claves faltantes en Iñaquito</p>
              <div className="rounded-lg bg-card border border-border p-3 text-xs min-h-24">
                {selected.missing_inaquito.length ? selected.missing_inaquito.join(", ") : "Sin diferencias"}
              </div>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers screens
// ─────────────────────────────────────────────────────────────────────────────
function ScreenLoading({ label }: { label: string }) {
  return (
    <div className="h-full flex items-center justify-center">
      <div className="text-center">
        <RefreshCw size={28} className="mx-auto text-accent animate-spin" />
        <p className="text-sm text-muted-foreground mt-3">{label}</p>
      </div>
    </div>
  );
}

function EmptyState({ title, description }: { title: string; description: string }) {
  return (
    <div className="h-full flex items-center justify-center p-6">
      <div className="max-w-md text-center bg-card border border-border rounded-2xl p-8 shadow-sm">
        <Database size={28} className="mx-auto text-accent" />
        <h3 className="text-lg font-semibold text-foreground mt-4">{title}</h3>
        <p className="text-sm text-muted-foreground mt-2">{description}</p>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Main App
// ─────────────────────────────────────────────────────────────────────────────
export default function App() {
  const [sessionState, setSessionState] = useState<SessionState | null>(null);
  const [booting, setBooting] = useState(true);
  const [screen, setScreen] = useState<Screen>("dashboard");
  const [dashboardData, setDashboardData] = useState<DashboardData | null>(null);
  const [notice, setNotice] = useState<{ type: "success" | "error" | "warning" | "info"; message: string } | null>(null);

  const csrfToken = sessionState?.csrf_token || "";
  const activeNode = sessionState?.active_node;
  const entities = sessionState?.entities || {};

  function notify(type: "success" | "error" | "warning" | "info", message: string) {
    setNotice({ type, message });
  }

  async function bootstrap() {
    setBooting(true);
    try {
      const payload = await api<SessionState>("/api/auth/session");
      setSessionState(payload);
    } finally {
      setBooting(false);
    }
  }

  async function loadDashboard() {
    if (!sessionState?.authenticated) return;
    try {
      const payload = await api<DashboardData>("/api/dashboard");
      setDashboardData(payload);
    } catch (err: any) {
      notify("error", err.message || "No se pudo cargar el dashboard.");
    }
  }

  useEffect(() => {
    bootstrap();
  }, []);

  useEffect(() => {
    if (sessionState?.authenticated) {
      loadDashboard();
    }
  }, [sessionState?.authenticated, sessionState?.active_node?.key]);

  async function handleLogin(username: string, password: string) {
    const payload = await api<SessionState & { ok: boolean }>("/api/auth/login", {
      method: "POST",
      body: JSON.stringify({ username, password }),
    });
    setSessionState(payload);
    setScreen("dashboard");
    notify("success", `Bienvenido, ${payload.user?.display_name || username}.`);
  }

  async function handleLogout() {
    try {
      await api<{ ok: boolean; message: string }>("/api/auth/logout", { method: "POST" }, csrfToken);
    } catch {
      // ignore logout backend errors if session already ended
    }
    setSessionState({ authenticated: false, csrf_token: "" });
    setDashboardData(null);
    setScreen("dashboard");
    notify("info", "Sesión cerrada.");
  }

  if (booting) {
    return <ScreenLoading label="Cargando aplicación..." />;
  }

  if (!sessionState?.authenticated || !sessionState.user || !activeNode || !sessionState.nodes) {
    return <LoginScreen onLogin={handleLogin} />;
  }

  const renderScreen = () => {
    if (!activeNode) return <EmptyState title="Nodo no disponible" description="No se pudo determinar el nodo activo." />;
    switch (screen) {
      case "dashboard":
        return <DashboardScreen data={dashboardData} />;
      case "historial":
        return entities.historiales ? <EntityScreen entity={entities.historiales} activeNode={activeNode} csrfToken={csrfToken} onNotify={notify} /> : <EmptyState title="Sin módulo" description="No hay metadata disponible." />;
      default:
        return entities[screen] ? <EntityScreen entity={entities[screen]} activeNode={activeNode} csrfToken={csrfToken} onNotify={notify} /> : <EmptyState title="Sin módulo" description="El mockup se cargó, pero no existe metadata para esta pantalla." />;
    }
  };

  return (
    <div className="flex h-screen w-screen overflow-hidden bg-background">
      <Sidebar screen={screen} onNav={setScreen} onLogout={handleLogout} />
      <div className="flex flex-col flex-1 overflow-hidden">
        <TopBar user={sessionState.user} activeNode={activeNode} />
        <div className="px-5 pt-4">
          {notice && <Alert type={notice.type} message={notice.message} onClose={() => setNotice(null)} />}
        </div>
        <main className="flex-1 overflow-hidden">{renderScreen()}</main>
      </div>
    </div>
  );
}
