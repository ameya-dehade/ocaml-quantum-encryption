
type t

@new external make: string => t = "WebSocket"

@set external onMessage: (t, {"data": string} => unit) => unit = "onmessage"
@set external onOpen: (t, unit => unit) => unit = "onopen"
@set external onClose: (t, unit => unit) => unit = "onclose"

@send external send: (t, string) => unit = "send"