import './main.css';
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';

const token = localStorage.getItem('token');

const app = Elm.Main.init({
  node: document.getElementById('root'),
  flags: token
});

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();


app.ports.storeToken.subscribe(function(token) {
  localStorage.setItem('token', token);
});

app.ports.logError.subscribe(function(log) {
  console.error(log);
});