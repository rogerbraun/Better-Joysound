updateResults = (query, kind) ->
  $.get("search", {query: query, kind:kind}, ((text) -> $("#results").html(text) ))

updatePeriodically = (interval, query, kind) ->
  callback = (data) ->
    if data == "false"
      clearInterval(interval)
    updateResults(query, kind)  
  $.get("running", {query: query}, callback)

setTimers = (query, kind) ->
  callback = (data) ->
    if data == "true"
      holdTheInterval = setInterval (-> updatePeriodically(holdTheInterval, query, kind) ), 3000
  $.get "running", {query: query}, callback

watchButtons = () ->
  buttons = $("button.forget")
  buttons.live "click", (-> removeRemembered(this.value))
  buttons = $("button.remember")
  buttons.live "click", (-> addRemembered(this.value))

removeRemembered = (song) -> 
  $.post("song/#{song}/forget",(-> updateBoth()))  
  return false

addRemembered = (song) -> 
  $.post("song/#{song}/remember",(-> updateBoth()))  
  return false

updateBoth = () ->
  $.get("remembered", ((text) -> $("#remembered").html(text)))
  $.get("search", {query: query, kind:kind}, ((text) -> $("#results").html(text) ))
  
toggle = (element) ->
  el = document.getElementById element
  if el.style.display == "" or el.style.display == "none"
    el.style.display = "block"
  else
    el.style.display = "none"
  return false;

osterhase = (form) ->
  text = form.query.value.toLowerCase()
  if text == "osterhase"
    alert("OSTERHASE!!!!")
    return false
  else
    return true
