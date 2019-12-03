import './main.css';
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';
import hash from 'object-hash';

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

app.ports.orderFromCache.subscribe(function(endpoint){
  console.log(endpoint);
  let key = hash(endpoint);
  console.log(key);
  let item = JSON.parse(localStorage.getItem(key) || "{}");
  console.log(item);
  if(item && item.endpoint && item.body && item.metadata){
    app.ports.listenToCache.send(item);
  } else {
    console.error("item " + key + " not found in cache");
  }
});

app.ports.putToCache.subscribe(function(item){
  console.log(item.endpoint);
  if(item && item.endpoint && item.body && item.metadata){
    let key = hash(item.endpoint);
    console.log(key);
    localStorage.setItem(key,JSON.stringify(item));
  } else {
    console.error("empty item");
  }
});