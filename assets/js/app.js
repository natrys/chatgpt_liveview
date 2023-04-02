// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

let Hooks = {}
Hooks.HandleQuestion = {
  mounted() {
    this.el.focus();

    this.el.addEventListener("keydown", (event) => {
      if ((event.altKey || event.shiftKey) && event.code == "Enter") {
        let session = event.shiftKey;
        this.pushEventTo("#chat-logic", "question-submit", {question: this.el.value, session: session});
        this.el.disabled = true;
        this.el.blur();
      };
    });

    this.el.addEventListener("click", () => {
      if (("Notification" in window) && (Notification.permission === "default")) {
        Notification.requestPermission().then((permission) => {
          if (permission === "granted") {
            console.log("notification permission granted");
          }
        })
      }
    })

    this.handleEvent("unfreeze-question-textarea", (_) => {
      this.el.disabled = false;
      this.el.focus();
    })
  },
}

Hooks.HandleChatUpdate = {
  updated() {
    if (typeof document.hidden !== "undefined") {
      if ((Notification.permission === "granted") && document.hidden) {
        new Notification("Answer received", {
          title: "ChatGPT",
          icon: "/favicon.png"
        });
      }
    }

    this.el.scrollTop = this.el.scrollHeight;
    let textarea = document.getElementById("question-textarea");
    textarea.value = "";
    textarea.disabled = false;
    textarea.focus();
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken }, hooks: Hooks })

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
