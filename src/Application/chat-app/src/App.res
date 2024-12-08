@react.component
let make = () => {
  let (username, setUsername) = React.useState(() => "")

  let handleUsernameSubmit = (name) => {
    setUsername(_prev => name)
  }

  <div className="container mx-auto h-screen flex flex-col justify-center items-center">
    {switch username {
      | "" => (
        <Login
          onSubmit={handleUsernameSubmit}
        />
      )
      | name => (
        <ChatBox currentUser={name} />
      )
    }}
  </div>
}