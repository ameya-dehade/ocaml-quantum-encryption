@react.component
let make = (~onSubmit: (string) => unit) => {
  let (username, setUsername) = React.useState(() => "")

  let handleInputChange = (event) => {
    let value = ReactEvent.Form.currentTarget(event)["value"]
    setUsername(_prev => value)
  }

  let handleButtonClick = (_) => {
    if (username !== "") {
      onSubmit(username)
      setUsername(_prev => "")
    }
  }

  <div className="card bg-neutral text-neutral-content p-4 rounded-lg">
    <h2 className="card-title text-center mb-4">{React.string("Enter Your Username")}</h2>
    <input
      type_="text"
      placeholder="Username"
      value={username}
      onChange={handleInputChange}
      className="input input-bordered w-full mb-4"
    />
    <button
      className="btn btn-primary w-full"
      onClick={handleButtonClick}
    >
      {React.string("Login")}
    </button>
  </div>
}
