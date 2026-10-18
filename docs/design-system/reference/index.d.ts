export type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger' | 'transport';
export interface ButtonProps { variant?: ButtonVariant; size?: 'md' | 'lg'; icon?: string; iconOnly?: boolean; label?: string; hotkey?: string; disabled?: boolean; onClick?: () => void; children?: any }
export interface SwitchProps { checked: boolean; onChange?: (v: boolean) => void; label: string }
export interface SliderProps { value: number; min?: number; max?: number; onChange?: (v: number) => void; icon?: string; label?: string; ariaLabel?: string; showValue?: boolean; format?: (v: number) => string }
export interface SegmentOption { id: string; label: string; key?: string; color?: string }
export interface SegmentedControlProps { options: SegmentOption[]; value: string; onChange?: (id: string) => void; label?: string }
export interface BadgeProps { tone?: 'neutral' | 'primary' | 'success' | 'danger'; dot?: boolean; children?: any }
export interface SceneRowProps { name: string; meta?: string; active?: boolean; playing?: boolean; cover?: string; src?: string; seed?: string; onClick?: () => void }
export interface SfxTileProps { label?: string; icon?: string; hotkey?: string; playing?: boolean; progress?: number; empty?: boolean; onClick?: () => void }
export interface AmbientRowProps { name: string; icon?: string; on: boolean; onToggle?: (v: boolean) => void; volume: number; onVolume?: (v: number) => void; pinned?: boolean }
export interface MusicCardProps { track: string; playing?: boolean; onToggle?: () => void; position?: number; duration?: number; levels?: number[] }
export interface MixerChannel { id: string; icon: string; label: string; value: number }
export interface MixerBarProps { track: string; playing?: boolean; onToggle?: () => void; channels: MixerChannel[] }
export interface NavItem { id: string; icon: string; label: string }
export interface NavRailProps { items: NavItem[]; active: string; onSelect?: (id: string) => void; open?: boolean }
export interface IconProps { name: string; size?: number }
export interface LogoProps { size?: number; wordmark?: boolean }
export type CoverKey = 'peaks' | 'tower' | 'forest' | 'sea' | 'gate' | 'dunes' | 'village';
export interface EqualizerProps { active?: boolean; bars?: number; height?: number; levels?: number[]; className?: string }
export interface SceneCoverProps { cover?: CoverKey; src?: string; seed?: string; dim?: number; fill?: boolean; height?: number | string; width?: number | string; radius?: number | string; className?: string; style?: any }
export interface TextFieldProps { label?: string; value?: string; defaultValue?: string; onChange?: (v: string) => void; placeholder?: string; icon?: string; type?: string; clearable?: boolean; hotkey?: string; hint?: string; error?: string; disabled?: boolean; width?: number | string; id?: string }
export interface SelectOption { id: string; label: string }
export interface SelectProps { label?: string; options: SelectOption[]; value?: string; defaultValue?: string; onChange?: (id: string) => void; icon?: string; hint?: string; disabled?: boolean; width?: number | string }
export interface CheckboxProps { label: string; description?: string; checked?: boolean; defaultChecked?: boolean; onChange?: (v: boolean) => void; disabled?: boolean }
export interface DropzoneProps { title?: string; hint?: string; overTitle?: string; active?: boolean; compact?: boolean; onBrowse?: () => void; onFiles?: (files: FileList) => void }
export interface ChipProps { label: string; icon?: string; selected?: boolean; onClick?: () => void; onRemove?: () => void }
export interface DialogAction { label: string; variant?: ButtonVariant; icon?: string; onClick?: () => void; disabled?: boolean }
export interface DialogProps { title: string; description?: string; icon?: string; tone?: 'neutral' | 'danger'; size?: 'sm' | 'md' | 'lg'; actions?: DialogAction[]; footNote?: string; onClose?: () => void; open?: boolean; inline?: boolean; children?: any }
export interface MenuItem { id?: string; label?: string; icon?: string; hotkey?: string; danger?: boolean; disabled?: boolean; checked?: boolean; separator?: boolean }
export interface MenuProps { items: MenuItem[]; onSelect?: (id: string) => void; label?: string }
export interface TooltipProps { label: string; hotkey?: string; placement?: 'top' | 'bottom'; open?: boolean; children?: any }
export interface ToastProps { title: string; message?: string; tone?: 'neutral' | 'success' | 'danger'; icon?: string; progress?: number; action?: { label: string; onClick?: () => void }; closable?: boolean; onClose?: () => void }
export interface ProgressBarProps { value?: number; label?: string; caption?: string; showValue?: boolean }
export interface EmptyStateProps { icon?: string; title: string; message?: string; action?: DialogAction; tone?: 'neutral' | 'danger' }
export interface TrackRowProps { title: string; kind?: 'music' | 'ambient' | 'sfx'; icon?: string; duration?: string; meta?: string; tags?: string[]; playing?: boolean; missing?: boolean; path?: string; onPlay?: () => void; onEdit?: () => void; onMore?: () => void }
export interface CatalogCardProps { kind?: 'scene' | 'media' | 'bundle'; title: string; author?: string; description?: string; count?: string; size?: string; status?: 'available' | 'installed' | 'update' | 'downloading'; progress?: number; cover?: CoverKey; src?: string; seed?: string; onAction?: () => void }
export interface ThemeColors { bg: string; surface: string; text: string; primary: string }
export interface ThemeCardProps { name?: string; colors?: ThemeColors; selected?: boolean; custom?: boolean; add?: boolean; onClick?: () => void }
export interface ShortcutRowProps { action: string; description?: string; keys: string[]; editable?: boolean; onEdit?: () => void }
