@react.component
let make = (~onSubmit: (string) => ()) => {
  let (text, setText) = React.useState(() => "")

  let handleKeyDown = (e) => {
    let key = ReactEvent.Keyboard.key(e)

    switch key {
      | "Enter" => {
        ReactEvent.Keyboard.preventDefault(e)

        onSubmit(text)
        setText((_) => "")
      } 
      | _ => ()
    }
  }

  let handleInputChange = (event) => {
    let value = ReactEvent.Form.currentTarget(event)["value"]
    setText((_) => value)
  }

  let handleButtonClick = (_) => {
    switch text {
      | "" => () 
      | text => {
        onSubmit(text)
        setText((_) => "")
      }
    }
  }

   <div className="flex items-center justify-center min-h-screen bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500">
    <div className="card bg-white text-black shadow-xl rounded-lg max-w-sm w-full p-6">
      <div className="card-body text-center">
        <h2 className="card-title text-2xl font-bold mb-4">
          {React.string("Welcome to Chat")}
        </h2>
        <p className="text-gray-600 mb-6">
          {React.string("Create your username to start chatting!")}
        </p>
        <input
          type_="text"
          placeholder="Enter username"
          className="input input-bordered w-full px-4 py-2 text-lg rounded-md focus:ring-2 focus:ring-blue-500 outline-none mb-4"
          value={text}
          onChange={handleInputChange}
          onKeyDown={handleKeyDown}
        />
        <div className="card-actions justify-center">
          <button
            className={`btn w-full py-2 text-lg rounded-md text-white font-semibold ${
              text === "" ? "bg-gray-400 cursor-not-allowed" : "bg-blue-500 hover:bg-blue-600"
            }`}
            onClick={handleButtonClick}
            disabled={text === ""}
          >
            {React.string("Login")}
          </button>
        </div>
      </div>
    </div>
  </div>
}