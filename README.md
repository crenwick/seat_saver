# Elm + Phoenix
## An updated version of [seat_saver](https://github.com/CultivateHQ/seat_saver)

Last year, CultivateHQ made a series of tutorials how out to make Elixir talk with Elm. Since then, Elm has gone through some major breaking changes. This is simply an updated version of that app.

## Running the app:

```sh
git clone git@github.com:crenwick/seat_saver.git
cd seat_saver

# For the http app (non phoenix channels), 
# run `git checkout http`

mix deps.get
mix ecto.create && mix ecto.migrate && mix run priv/repo/seeds.exs
npm install # this will install elm packages too

iex -S mix phoenix.server # requires postgres running
```
Now you can visit `localhost:4000` from your browser.

## Differences between this and [CultivateHQ/seat_saver](https://github.com/CultivateHQ/seat_saver)

### Elixir:
Both have identical http setups (via the `http` branch), and both have almost identical Elixir setups. However, the `SeatSaver.SeatsChannel` route of `request_seat` replies with the new seat object (instead of `{:noreply}`). 
The Elm app uses this reply to update the model.

### Elm:
Unlike CultivateHQ's version, this app does not use ports with the `web/static/js/socket.js` file. Instead, it uses a native implmentation of WebSockets/Phoenix channels via the [elm-phoenix-socket package](http://package.elm-lang.org/packages/fbonetti/elm-phoenix-socket).
This ends up with a cleaner, more Elm-like implmentation. However, unlike Phoenix' `socket.js`, Elm's WebSockets does not fall back to longpolling.

Like CultivateHQ's, when this app loads it sets up a listener on both `set_seats` and `seat_updated` channels. However, this app also handles the reply from the `request_seat` request and updates the model with that, too.
