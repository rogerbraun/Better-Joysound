var addRemembered, osterhase, removeRemembered, setTimers, toggle, updateBoth, updatePeriodically, updateResults, watchButtons;
updateResults = function(query, kind) {
  return $.get("search", {
    query: query,
    kind: kind
  }, (function(text) {
    return $("#results").html(text);
  }));
};
updatePeriodically = function(interval, query, kind) {
  var callback;
  callback = function(data) {
    if (data === "false") {
      clearInterval(interval);
    }
    return updateResults(query, kind);
  };
  return $.get("running", {
    query: query
  }, callback);
};
setTimers = function(query, kind) {
  var callback;
  callback = function(data) {
    var holdTheInterval;
    if (data === "true") {
      return holdTheInterval = setInterval((function() {
        return updatePeriodically(holdTheInterval, query, kind);
      }), 3000);
    }
  };
  return $.get("running", {
    query: query
  }, callback);
};
watchButtons = function() {
  var buttons;
  buttons = $("button.forget");
  buttons.live("click", (function() {
    return removeRemembered(this.value);
  }));
  buttons = $("button.remember");
  return buttons.live("click", (function() {
    return addRemembered(this.value);
  }));
};
removeRemembered = function(song) {
  $.post("song/" + song + "/forget", (function() {
    return updateBoth();
  }));
  return false;
};
addRemembered = function(song) {
  $.post("song/" + song + "/remember", (function() {
    return updateBoth();
  }));
  return false;
};
updateBoth = function() {
  $.get("remembered", (function(text) {
    return $("#remembered").html(text);
  }));
  return $.get("search", {
    query: query,
    kind: kind
  }, (function(text) {
    return $("#results").html(text);
  }));
};
toggle = function(element) {
  var el;
  el = document.getElementById(element);
  if (el.style.display === "" || el.style.display === "none") {
    el.style.display = "block";
  } else {
    el.style.display = "none";
  }
  return false;
};
osterhase = function(form) {
  var text;
  text = form.query.value.toLowerCase();
  if (text === "osterhase") {
    alert("OSTERHASE!!!!");
    return false;
  } else {
    return true;
  }
};