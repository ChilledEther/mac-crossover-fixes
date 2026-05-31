/// Trait representing a modular compatibility patch inside a Wine/CrossOver bottle.
/// 
/// Implementing this trait registers a patch within the dynamic list, automatically
/// rendering it in the GUI checklist and enabling host-side CLI management.
pub trait Patch {
    fn id(&self) -> &'static str;
    fn name(&self) -> &'static str;
    fn description(&self) -> &'static str;
    fn is_enabled(&self) -> Result<bool, String>;
    fn enable(&self) -> Result<(), String>;
    fn disable(&self) -> Result<(), String>;
}

mod gamepad;
mod dwrite;
mod crash_dialog;

pub use gamepad::GamepadPatch;
pub use dwrite::DWritePatch;
pub use crash_dialog::CrashDialogPatch;

pub fn get_all_patches() -> Vec<Box<dyn Patch>> {
    vec![
        Box::new(GamepadPatch),
        Box::new(DWritePatch),
        Box::new(CrashDialogPatch),
    ]
}
