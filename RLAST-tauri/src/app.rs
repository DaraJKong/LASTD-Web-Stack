use leptos::leptos_dom::ev::SubmitEvent;
use leptos::*;
use serde::{Deserialize, Serialize};
use serde_wasm_bindgen::to_value;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_namespace = ["window", "__TAURI__", "core"])]
    async fn invoke(cmd: &str, args: JsValue) -> JsValue;
}

#[derive(Serialize, Deserialize)]
struct GreetArgs<'a> {
    name: &'a str,
}

#[component]
pub fn App() -> impl IntoView {
    let (name, set_name) = create_signal(String::new());
    let (greet_msg, set_greet_msg) = create_signal(String::new());

    let update_name = move |ev| {
        let v = event_target_value(&ev);
        set_name.set(v);
    };

    let greet = move |ev: SubmitEvent| {
        ev.prevent_default();
        spawn_local(async move {
            let name = name.get_untracked();
            if name.is_empty() {
                return;
            }

            let args = to_value(&GreetArgs { name: &name }).unwrap();
            // Learn more about Tauri commands at https://tauri.app/v1/guides/features/command
            let new_msg = invoke("greet", args).await.as_string().unwrap();
            set_greet_msg.set(new_msg);
        });
    };

    view! {
        <main class="h-full flex flex-col items-center justify-center">
            <div class="card bg-neutral shadow-xl">
                <div class="p-9">
                    <div class="flex justify-center gap-12 mb-12">
                        <a href="https://tauri.app" target="_blank">
                            <img src="public/tauri.svg" class="h-36" alt="Tauri logo"/>
                        </a>
                        <a href="https://leptos.dev/" target="_blank">
                            <img src="public/leptos.svg" class="h-36" alt="Leptos logo"/>
                        </a>
                    </div>

                    <div class="divider">"Click on the Tauri and Leptos logos to learn more."</div>
                </div>

                <div class="card-body bg-base-100">
                    <form class="flex gap-3" on:submit=greet>
                        <input
                            id="greet-input"
                            placeholder="Enter a name..."
                            on:input=update_name
                            class="input input-bordered flex-1"
                        />
                        <button type="submit" class="btn btn-primary">
                            "Greet"
                        </button>
                    </form>

                    <p class="text-center text-lg mt-6">
                        <b>{move || greet_msg.get()}</b>
                    </p>
                </div>
            </div>
        </main>
    }
}
