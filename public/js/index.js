'use strict';

// Push the user to the results page
function doWordSearch() {
  hide_all_alerts();

  var word_val = $('#words').val();
  if (word_val === "") {
    $("#word_alert").removeClass("hidden");
    $("#word_alert_msg").html("You haven't entered any words or letters");
  } else {
    window.location = "/sleuth/" + encodeURI(word_val);
  }
  return false;
}

function doNumbers() {
  hide_all_alerts();

  var src_num_val = $('#numbers').val();
  var target_val = $('#target').val();

  if (src_num_val === "") {
    $("#number_alert").removeClass("hidden");
    $("#number_alert_msg").html("You haven't entered any source numbers");
  } else if (target_val === "") {
    $("#number_alert").removeClass("hidden");
    $("#number_alert_msg").html("You haven't entered a target number");
  } else {
    window.location = "/sleuth/" + encodeURI(src_num_val) + "/" + encodeURI(target_val)
  }

  return false;
}

function hide_all_alerts() {
  $(".alert").addClass("hidden");
}
