@react.component
let make = (~onSubmit: string => unit) => {
  let (text, setText) = React.useState(() => "")

  let handleInputChange = (event) => {
    let value = ReactEvent.Form.currentTarget(event)["value"]
    setText(_prev => value)
  }

  let handleSendClick = (_) => {
    if (text !== "") {
      onSubmit(text)
      setText(_prev => "")
    }
  }

  let handleKeyDown = (event) => {
    if (ReactEvent.Keyboard.key(event) === "Enter" && text !== "") {
      ReactEvent.Keyboard.preventDefault(event)
      onSubmit(text)
      setText(_prev => "")
    }
  }

  <div className="flex items-center">
    <input
      type_="text"
      placeholder="Type a message"
      value={text}
      onChange={handleInputChange}
      onKeyDown={handleKeyDown}
      className="input input-bordered flex-1 mr-2"
    />
    <button
      className="btn btn-primary"
      onClick={handleSendClick}
    >
      {React.string("Send")}
    </button>
  </div>
}
