import './main.css';
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';

const state = localStorage.getItem('state');

const app = Elm.Main.init({
  node: document.getElementById('root'),
  flags: state
});

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();


app.ports.storeState.subscribe(function(state) {
  if(state===""){
    localStorage.removeItem('state')
  } else {
    localStorage.setItem('state', state);
  }
});

app.ports.logError.subscribe(function(log) {
  console.error(log);
});

document.addEventListener('fullscreenchange',function (event) {
      app.ports.fullScreenChange.push(document.fullscreenElement!=null);
});