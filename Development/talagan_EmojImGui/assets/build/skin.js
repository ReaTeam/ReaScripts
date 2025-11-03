
document.addEventListener("DOMContentLoaded", function(event) {
  const selectElement = document.querySelector("#skin-selector");

  selectElement.addEventListener("change", (event) => {
    let chars = document.querySelectorAll('.test')
    let wskin = selectElement.value
    for(i=0;i<chars.length;i++) {
      let e     = chars[i]
      let skin  = e.dataset.skin

      let should_show = false;
      if(wskin == -1 || skin == null || skin == undefined || skin == '') {
        should_show = true
      }
      else {
        should_show = skin.split(",").includes(wskin)
      }
      e.style.display = (should_show)?('inline-block'):('none')
    }
  });

});
