-- @description Turing Complete Web Interface
-- @author Rek's Effeks
-- @version 0.alpha2
-- @provides
--   [main] rxfx_CustomFancy_CycleTrackRecordArm.lua
--   [main] rxfx_CustomFancy_SetTimeSelFromMarkers.lua
--   [main] rxfx_CustomFancy_NewProject.lua
--   [main] rxfx_CustomFancy_OpenSelectedProject.lua
--   [main] rxfx_CustomFancy_ReadCurrentProject.lua
--   [main] rxfx_CustomFancy_RenameTrackFromExtState.lua
--   [main] rxfx_CustomFancy_SaveProjectAs.lua
--   [main] rxfx_CustomFancy_SendProjectList.lua
--   [main] rxfx_CustomFancy_SendTempo.lua
--   [main] rxfx_CustomFancy_SetTimeSig.lua
-- @about
--   A web interface (adapted from Fancier.html) that can fully* control Reaper. Includes project save/load, basic track management, time selection controls and various bugfixes over the original.
--
--   NOTE: This is almost certainly not compatible with your existing workflow. It's designed to be the ONLY input method for a HEADLESS install of Reaper, specialized towards multitracking audio, and tested primarily on Raspberry Pi (Linux). This means significant caveats, including the need for a fairly specific project file structure. I have no intention of supporting midi in any form and I think it's unlikely the interface will work on Windows.
--
--   INSTALL INSTRUCTIONS: I don't know how web interfaces will be set up in ReaPack, but wherever the HTML file ends up, you should put the .ttf file for the OpenSans font beside it: https://fonts.google.com/specimen/Open+Sans
--
--   You also need to set your default project path in reaper-extstate.ini, in the form:
--   [Fanciest]
--   ProjectFolder=/path/to/folder/
--
--   Include the slash at the end.

<!doctype html>
<html><head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1, user-scalable=0"/>
<meta name="apple-mobile-web-app-capable" content="yes"/>
<meta name="mobile-web-app-capable" content="yes"/>
<title>Rek's Turing-complete Controller</title>
<link rel="icon" type="image/svg+xml" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'><rect width='32' height='32' fill='%231a1a1a'/><polygon fill='%2300FE95' points='10,8 10,24 26,16'/></svg>">
<!-- <link href="http://fonts.googleapis.com/css?family=Open+Sans:400,300,700" rel="stylesheet" type="text/css"> -->
<style>
    @font-face {
    font-family: 'Open Sans';
    src: url('OpenSans-VariableFont_wdth,wght.ttf') format('truetype');
}
</style>
<script src="main.js"></script>

<style type="text/css">

    body {
        background-color:#333333;
        color:#A9ABAB;
        font-family: 'Open Sans',sans-serif;
        font-size: 0.9em;
        margin:0px;
        user-select: none;
        cursor: default;
        }

    #colWrap {
        display:flex;
        flex-direction: column;
        }
    #col1 {
            flex-basis:100%;
        }
    #tracks {
            flex-basis:100%;
            }
    @media only screen
      and (min-device-width: 768px)
      and (orientation: landscape)
      and (-webkit-min-device-pixel-ratio: 1) {
        #colWrap {
            flex-direction: row;
            }
        #col1 {
            flex-basis:50%;
            }
        #tracks {
            flex-basis:50%;
            border-left-style:solid;
            border-left-color: #1A1A1A;
            }
        }

    #optionsBar {}

    .trackRow1{
        will-change: transform;
        }
    .trackRow2{
        will-change: transform;
        }

    .optionsBar {
        height : 0px;

        }
    .button:hover .mouseover {
        visibility:visible;
        }
    .button:active .mouseover {
        visibility:hidden;
        pointer-events:all;
        }
    .button:active .shadow {
        visibility: hidden;
        }
    .button:active .gloss {
        visibility: hidden;
        }
    .button:active .active {
        visibility: visible;
        }

</style>

<script type="text/javascript">

var markerDeletePending = {};

wwr_req_recur("TRANSPORT;BEATPOS",10);
wwr_req_recur("NTRACK;TRACK;GET/40364;GET/1157;GET/41819",10);
wwr_req_recur("MARKER;REGION",500);
wwr_start();

var last_transport_state = -1, mouseDown = 0, last_time_str = "",
    last_metronome = false,  nTrack = 0, last_repeat = false, snapState = 0, prerollState = 0,
    drawnSig=0, drawnBeat=0, ts_numerator=0, ts_denominator=0, playPosSeconds=0, statusPosition=[], statusPositionAr=[],
    startX = 0, joggerAgg = 0, recarmCountAr = [], recarmCount = 0, newPos = -1, lastMrMapStr = "", newMrMapLength = -1,
    trackHeightsAr = [], trackColoursAr = [], trackNumbersAr = [], trackNamesAr = [],  trackVolumeAr = [], trackPanAr = [],
    trackFlagsAr = [], trackSendCntAr = [], trackRcvCntAr = [], trackHwOutCntAr = [], trackSendHwCntAr = [], trackPeakAr = [], trackMeterAr = [], faderConAr = [], trackArmBtnAr = [], trackArmChannelAr = [],
    hereCss = document.styleSheets[1], wwr_listeners = [], timesel_points = [], transitions = 1;

function setTextForObject(obj, text) {
  if (obj.lastChild) obj.lastChild.nodeValue = text;
  else obj.appendChild(document.createTextNode(text));
  }

function lumaOffset(c){
    var c = c.substring(1);
    var rgb = parseInt(c, 16);
    var r = (rgb >> 16) & 0xff;
    var g = (rgb >>  8) & 0xff;
    var b = (rgb >>  0) & 0xff;
    var luma = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    function componentToHex(c) {
        var hex = c.toString(16);
        return hex.length == 1 ? "0" + hex : hex;
        }
    if (luma < 150) {r = r+150; g = g+150; b = b+150}
    if (luma > 150) {r = r-120; g = g-120; b = b-120}
    if(r<0){r=0}; if(g<0){g=0}; if(b<0){b=0}
    if(r>255){r=255}; if(g>255){g=255}; if(b>255){b=255}
    return "#" + componentToHex(r) + componentToHex(g) + componentToHex(b);
}

function mouseDownEventHandler(msg) {
  return function(e) {
    if (typeof e == 'undefined') e=event;
    if (e.preventDefault) e.preventDefault();
    wwr_req(msg);
    return false;
  }
}

function mouseUpHandler(event){mouseDown = 0;}
function mouseDownHandler(event, target){mouseDown = 1;}
function mouseLeaveHandler(event){mouseDown = 0;}
function mouseMoveHandler(event){
    if (mouseDown != 1){ return; }
    else {
        var volTrackWidth = (this.getBoundingClientRect()["width"]);
        var volThumbWidth = volTrackWidth * 0.14375;
        var panOffset = volTrackWidth * (40/320);   // left margin for pan knob
        var delOffset = volTrackWidth * (35/320);   // right margin for delete button
        var volThumbTrackWidth = (volTrackWidth - volThumbWidth - panOffset - delOffset);
        var volThumbTrackLEdge = this.getBoundingClientRect()["left"];
        offsetX = (event.pageX - volThumbTrackLEdge - (volThumbWidth / 2));

        if (event.changedTouches != undefined) { //we're doing touch stuff
            offsetX = (event.changedTouches[0].pageX - volThumbTrackLEdge - (volThumbWidth / 2));
            }
        if(offsetX<panOffset){offsetX=panOffset};
        if(offsetX>volThumbTrackWidth+panOffset){offsetX=volThumbTrackWidth+panOffset};

        var volThumb = this.firstChild.getElementsByClassName("fader")[0];
        var offsetX320 = offsetX * (320 / volTrackWidth);
        var vteMove320 = "translate(" + offsetX320 + " 0)";
        volThumb.setAttributeNS(null, "transform", vteMove320);
        var volOutput = ((offsetX - panOffset)  / volThumbTrackWidth);
        var volOutputdB = Math.pow(volOutput, 4) * 4;
        wwr_req("SET/TRACK/" + this.id + "/VOL/" + volOutputdB)
        }
    }

var thisSendTrackId=0, sendOutputdB=0;

function sendMouseMoveHandler(event){
    if (mouseDown != 1){ return; }
    else {
        var sendTrackWidth = this.getElementsByClassName("sendBg")[0].getBoundingClientRect()["width"];
        var sendThumbWidth = this.getElementsByClassName("sendBg")[0].getBoundingClientRect()["height"];
        var sendThumbTrackWidth = (sendTrackWidth - sendThumbWidth);
        var sendThumbTrackLEdge = this.getElementsByClassName("sendBg")[0].getBoundingClientRect()["left"];

        offsetX = event.pageX - sendThumbTrackLEdge - (sendThumbWidth / 2);
        if (event.changedTouches != undefined) { //we're doing touch stuff
            offsetX = (event.changedTouches[0].pageX - sendThumbTrackLEdge - (sendThumbWidth / 2));
            }
        if(offsetX<0){offsetX=0};
        if(offsetX>sendThumbTrackWidth){offsetX=sendThumbTrackWidth};

        var offsetX262 = offsetX * (262 / sendTrackWidth) + 26;
        var sendThumb = this.getElementsByClassName("sendThumb")[0];
        sendThumb.setAttributeNS(null, "cx", offsetX262 );
        var sendLine = this.getElementsByClassName("sendLine")[0];
        sendLine.setAttributeNS(null, "x2", offsetX262 );

        var sendOutput = (offsetX  / sendThumbTrackWidth);
        sendOutputdB = Math.pow(sendOutput, 4) * 4;
        thisSendTrackId = (this.parentNode.id).slice(10);
        wwr_req("SET/TRACK/" + thisSendTrackId + "/SEND/" + this.id + "/VOL/" + sendOutputdB)
        }
    }

function volFaderConect(content, thumb){
    content.addEventListener("mousemove", mouseMoveHandler, false);
    content.addEventListener("touchmove", mouseMoveHandler, false);
    content.addEventListener("mouseleave", mouseLeaveHandler, false);
    content.addEventListener("mouseup", mouseUpHandler, false);
    content.addEventListener("touchend", mouseUpHandler, false);
    thumb.addEventListener("mousedown", function (event) {mouseDownHandler(event, event.srcElement)}, false);
    thumb.addEventListener('touchstart', function(event){
        if (event.touches.length > 0) mouseDownHandler(event, event.srcElement);
        event.preventDefault(); }, false);
    }

function sendMouseUpHandler(event){
    wwr_req("SET/TRACK/" + thisSendTrackId + "/SEND/" + this.id + "/VOL/" + sendOutputdB + "e");
    mouseDown = 0;
    }

function elAttribute(id,attribute,value){
    if(document.getElementById(id)){
        document.getElementById(id).setAttributeNS(null, attribute, value);
        }
    }

function updateTimeSelDisplay(args) {
    var bar = document.getElementById("timeSelBar");
    if (!bar) return;
    if (!args || args.length <2 || args.includes(null) || args[0]==args[1]) {
        bar.setAttributeNS(null, "visibility", "hidden");
        return;
    }
    var fromX = args[0], toX = args[1];
    relatives = ["leftEdge", "prev", "same", "next", "rightEdge"];
    values = [45.6, 102.5, 159.4, 216.2, 273.1];
    fromX = values[ relatives.indexOf(fromX) ];
    toX = values[ relatives.indexOf(toX) ];
    var left  = Math.min(fromX, toX);
    var width = Math.abs(toX - fromX);
    bar.setAttributeNS(null, "x", left);
    bar.setAttributeNS(null, "width", width);
    bar.setAttributeNS(null, "visibility", "visible");
}

function wwr_onreply(results) {
   /*var resultsDisplay = document.getElementById("_results");
    if(resultsDisplay!=null){
        var _backLoaded = document.getElementById("backLoad");
        _backLoaded.style.display = "block";
        resultsDisplay.innerHTML = results;
        } */

  var ar = results.split("\n");
  for (var x=0;x<ar.length;x++) {
    var tok = ar[x].split("\t");
    if (tok.length > 0) switch (tok[0]) {
      case "TRANSPORT":
        if (tok.length > 4) {
            var backLoaded = document.getElementById("backLoad");
            if(backLoaded!=null){
                if (tok[1] != last_transport_state) {
                last_transport_state=tok[1];
                document.getElementById("playButtonOff").style.visibility = (last_transport_state&1) ? "hidden" : "visible";
                document.getElementById("playButtonOn").style.visibility = (last_transport_state&1) ? "visible" : "hidden";
                document.getElementById("pauseButtonOff").style.visibility = (last_transport_state&2) ? "hidden" : "visible";
                document.getElementById("pauseButtonOn").style.visibility = (last_transport_state&2) ? "visible" : "hidden";
                document.getElementById("record_off").style.visibility = (last_transport_state&4) ? "hidden" : "";
                document.getElementById("record_on").style.visibility = (last_transport_state&4) ? "visible" : "";
                document.getElementById("armed_text").style.visibility = (last_transport_state&4) ? "hidden" : "";
                document.getElementById("armed_count").style.visibility = (last_transport_state&4) ? "hidden" : "";
                document.getElementById("abort_text").style.visibility = (last_transport_state&4) ? "visible" : "";
                document.getElementById("abort_cross").style.visibility = (last_transport_state&4) ? "visible" : "";
                }
            if (tok[3] != last_repeat) {
                last_repeat = tok[3];
                document.getElementById("repeat_off").style.visibility = (last_repeat>0) ? "hidden" : "";
                document.getElementById("repeat_on").style.visibility = (last_repeat>0) ? "visible" : "";
                }
            var statusDisplay = document.getElementById("status");

            //make an array of the current position and its unit
            statusPosition[0] = tok[4];
            statusPositionAr = tok[4].split(".");
            if(statusPositionAr[1]==undefined){
                if(statusPositionAr[0].match(":")){statusPosition[1] = "Hours:Minutes:Seconds:Frames";}
                else{statusPosition[1] = "samples / frames";}
                }
            else{if(statusPositionAr[1].length==3){
                    if(statusPositionAr[0].match(":")){statusPosition[1] = "Minutes:Seconds";}
                    else{statusPosition[1] = "Seconds";}
                    }
                  else{
                      statusPosition[1] = "Measures.Beats";
                      if(Number(statusPositionAr[0])<1) {
                          statusPositionAr[0] = (Number(statusPositionAr[0])-1).toString();
                          statusPosition[0] = statusPositionAr.join(".");
                      }
                  }
                }
            document.getElementById("timeUnits").textContent = statusPosition[1];

            joggerAggSign = Math.sign(joggerAgg);
            if(joggerAgg!=0){
                var joggerAggExp = Math.exp(Math.abs(joggerAgg)) * Math.sign(joggerAgg);
                if(statusPosition[1]=="Measures.Beats"){
                    statusJogging = BtoMB(Math.floor(Math.exp(Math.abs(joggerAgg)))) * Math.sign(joggerAgg) + ".00";
                    }
                else{statusJogging = joggerAggExp.toPrecision(4) + " s";}
                statusDisplay.textContent = statusJogging;
                statusDisplay.style.fill = (joggerAggSign<0) ? "#FE003B" : "#00FE95";
                }
            else {
                statusDisplay.textContent = statusPosition[0];
                statusDisplay.style.fill = "#a8a8a8";
                }
            if (tok[2] != playPosSeconds) {playPosSeconds=tok[2];}
        }
            if (tok[4]<1) {
                last_time_str = tok[4]-1;
            } else {
                last_time_str = tok[4];
            }
        }
      break;
      case "CMDSTATE":
        var buttonMetro = document.getElementById("buttonMetro");
        if (tok[1] == 40364 && buttonMetro) {
            if(last_metronome==1){
                    buttonMetro.childNodes[3].setAttributeNS(null, "visibility", "visible");
                    buttonMetro.childNodes[7].setAttributeNS(null, "visibility", "hidden");
                    }
                else{
                    buttonMetro.childNodes[3].setAttributeNS(null, "visibility", "hidden");
                    buttonMetro.childNodes[7].setAttributeNS(null, "visibility", "visible");
                    }
                last_metronome = tok[2];
            }

        var buttonPreroll = document.getElementById("prerollBg");
        if (tok[1] == 41819 && buttonPreroll) {
            document.getElementById("prerollBg").setAttributeNS(null, "opacity", tok[2]>0 ? "1" : "0.2");
            document.getElementById("prerollBg").setAttributeNS(null, "fill", tok[2]>0 ? "#8a9999" : "#262626");
        }

        var buttonSnap = document.getElementById("buttonSnap");
        if (tok[1] == 1157 && buttonSnap) {
            if (tok[2] != snapState) {
                if(snapState==0){
                    buttonSnap.childNodes[3].setAttributeNS(null, "visibility", "visible");
                    buttonSnap.childNodes[7].setAttributeNS(null, "visibility", "hidden");
                    }
                else{
                    buttonSnap.childNodes[3].setAttributeNS(null, "visibility", "hidden");
                    buttonSnap.childNodes[7].setAttributeNS(null, "visibility", "visible");
                    }
                snapState = tok[2];
                }
            }
      break;
      case "BEATPOS":
        var playLine = document.querySelector('#playLine');
        if (tok.length > 5 && playLine) {
            var playLineCirc = 301.1;
            var playLineArc = playLineCirc - (playLineCirc / tok[6]);
            //var playLineRotate = (360 / tok[6]) * tok[5]; //freewheeling play line
            thisBeat=Math.round(tok[5]);
            var playLineRotate = (360 / tok[6]) * thisBeat;
            thisSig=tok[6];
                if (drawnSig!=thisSig || drawnBeat!=thisBeat && playLine){
                    playLine.setAttributeNS(null, "stroke-dasharray", playLineCirc);
                    playLine.setAttributeNS(null, "stroke-dashoffset", playLineArc);
                    playLine.setAttribute("transform","rotate(" + playLineRotate + ",151.8,52.4)");
                    }
            ts_numerator = tok[6];
            ts_denominator = tok[7];
            document.getElementById("tsNum").textContent = ts_numerator;
            document.getElementById("tsDen").textContent = ts_denominator;
              }
      break;

      case "REGION_LIST":
            g_regions = [];
            break;
      case "REGION":
            g_regions.push(tok);
            break;
      case "MARKER_LIST":
            g_markers = [];
            break;
      case "MARKER":
            g_markers.push(tok);
            break;
      case "MARKER_LIST_END":
            var pos = parseFloat(playPosSeconds);
            var previ=-1, thisi=-1, nexti=-1;
        break;

        case "REGION_LIST_END":

            //assemble mrMap array : time, marker number, region start number, region end number.
            for (var i=0; i<g_regions.length; i++) {
                if(g_regions[i][5]==0){g_regions[i][5]=25198720;} // Give uncoloured regions a colour.
                }
            for (var i=0; i<g_markers.length; i++) {
                if(g_markers[i][4]==0){g_markers[i][4]=25198720;} // Give uncoloured markers a colour.
                }
            var mrMapAr = [];
            for (var i=0; i<g_regions.length*2; i++) {
                mrMapAr[i] = [];
                if(i<g_regions.length){                             //add the region starts to the ar
                    mrMapAr[i][0] = g_regions[i][3];
                    mrMapAr[i][2] = g_regions[i][2];
                    }
                else{                                               //add the region ends to the ar
                    mrMapAr[i][0] = g_regions[i-g_regions.length][4];
                    mrMapAr[i][3] = g_regions[i-g_regions.length][2];
                    }
                }
            for (var i=0; i<g_markers.length; i++) {                //add the markers to the ar
                mrMapAr[i+(g_regions.length*2)] = [];
                mrMapAr[i+(g_regions.length*2)][0] = g_markers[i][3];
                mrMapAr[i+(g_regions.length*2)][1] = g_markers[i][2];
                }

            for (var i=0; i<mrMapAr.length; i++) {                  //prep times for sorting
                posToSix = parseFloat(mrMapAr[i][0]).toFixed(6);
                mrMapAr[i][0] = parseFloat(posToSix);
                }

            mrMapAr.sort(function(a, b) {                           //sort into time order
                return (a[0] === b[0] ? 0 : (a[0] < b[0] ? -1 : 1));
                });

            function mergeAt(idx){
                if(mrMapAr[i-1][idx]){a=mrMapAr[i-1][idx]}else{a=0};
                if(mrMapAr[i][idx]){b=mrMapAr[i][idx]}else{b=0};
                mrMapAr[i-1][idx] = parseFloat(a)+parseFloat(b);
                }

            var mergeDone=0;
            if (mrMapAr.length === 1) {
                mergeDone=1;
            } else {
                for (var i=1; i<mrMapAr.length; i++) {                  //merge cells if at same time, delete the duplicate
                    if(mrMapAr[i-1] && mrMapAr[i][0]===mrMapAr[i-1][0]){
                        mergeAt(1); mergeAt(2); mergeAt(3);
                        mrMapAr.splice(i,1);
                        }
                    if(i==(mrMapAr.length-1)){mergeDone=1}
                    }
            }

            var prevl=-1, thisl=-1, nextl=-1;
            var mrMapStr = JSON.stringify(mrMapAr);
            if(mrMapAr.length===0){mergeDone=1;}
            if(mergeDone==1){
                for (var i=0; i<mrMapAr.length; i++){
                    var diff = (mrMapAr[i][0] - pos);
                    if(diff<0){
                        if(i>prevl){prevl = i}
                        }
                    if (diff==0) {thisl = i};
                    if(diff>0){
                        if(i>nextl){nextl = i; break;}
                        }
                    }
                }

            function getValuesFromId(array,id,colourIdx) {
                for (var i=0, len=array.length; i<len; i++) {
                    if(array[i][2]==id){return [id,(array[i][1]),(array[i][colourIdx])]}
                    }
                return [0,0,0];
                }

            var nextPrevSvg = document.getElementById("nextPrev");
            if((pos!=newPos || mrMapAr.length!=newMrMapLength || mrMapStr!=lastMrMapStr) && mergeDone==1 && nextPrevSvg){
                var rIdxAsg = [];
                search: for(i=0; i<4; i++){                         // 4 is the maximum drawable number of regions
                    if(mrMapAr[prevl] && mrMapAr[prevl][3]>=1){               //region end at prev?
                        var q = parseFloat(mrMapAr[prevl][3]);
                            if(rIdxAsg.indexOf(q)==-1){rIdxAsg[i] = q; continue search;}
                        }
                    if(mrMapAr[prevl] && mrMapAr[prevl][2]>=1){               //region start at prev?
                        var q = parseFloat(mrMapAr[prevl][2]);
                            if(rIdxAsg.indexOf(q)==-1){rIdxAsg[i] = q; continue search;}
                        }
                    if(mrMapAr[thisl] && mrMapAr[thisl][3]>=1){               //region end at this?
                        var q = parseFloat(mrMapAr[thisl][3]);
                            if(rIdxAsg.indexOf(q)==-1){rIdxAsg[i] = q; continue search;}
                        }
                    if(mrMapAr[thisl] && mrMapAr[thisl][2]>=1){               //region start at this?
                        var q = parseFloat(mrMapAr[thisl][2]);
                            if(rIdxAsg.indexOf(q)==-1){rIdxAsg[i] = q;continue search;}
                        }
                    if(mrMapAr[nextl] && mrMapAr[nextl][3]>=1){               //region end at next?
                        var q = parseFloat(mrMapAr[nextl][3]);
                            if(rIdxAsg.indexOf(q)==-1){rIdxAsg[i] = q; continue search}
                        }
                    if(mrMapAr[nextl] && mrMapAr[nextl][2]>=1){               //region start at next?
                        var q = parseFloat(mrMapAr[nextl][2]);
                            if(rIdxAsg.indexOf(q)==-1){rIdxAsg[i] = q;}
                        }
                    }

                function getValFromAr(array,id,idLoc,valLoc) {
                    for (var i=0, len=array.length; i<len; i++) {
                        if(array[i][idLoc]==id){return array[i][valLoc];}
                        }
                    return;
                    }

                for(i=1;i<5;i++){
                    select_points = [];
                    this['r'+i+'StalkLx'] = 45.6;
                    this['r'+i+'StalkRx'] = 273.1;
                    if(rIdxAsg[i-1] && rIdxAsg[i-1]>=0){
                        this['r'+i+'Idx'] = rIdxAsg[i-1];
                        this['r'+i+'Name'] = getValFromAr(g_regions,rIdxAsg[i-1],2,1);
                        this['col'+i] = getValFromAr(g_regions,rIdxAsg[i-1],2,5);
                        this['rCol'+i] = "#" + (this['col'+i]|0x1000000).toString(16).substr(-6);
                        if(prevl>=0 && mrMapAr[prevl][3] == rIdxAsg[i-1]){this['r'+i+'StalkRx'] = 102.5;}
                        if(prevl>=0 && mrMapAr[prevl][2] == rIdxAsg[i-1]){this['r'+i+'StalkLx'] = 102.5;}
                        if(thisl>=0 && mrMapAr[thisl][2] == rIdxAsg[i-1]){this['r'+i+'StalkLx'] = 159.4;}
                        if(thisl>=0 && mrMapAr[thisl][3] == rIdxAsg[i-1]){this['r'+i+'StalkRx'] = 159.4;}
                        if(nextl>=0 && mrMapAr[nextl][2] == rIdxAsg[i-1]){this['r'+i+'StalkLx'] = 216.2;}
                        if(nextl>=0 && mrMapAr[nextl][3] == rIdxAsg[i-1]){this['r'+i+'StalkRx'] = 216.2;}
                        document.getElementById('region'+i).setAttributeNS(null, "visibility", "visible");
                        document.getElementById('r'+i+'Rect').setAttributeNS(null, "fill", this['rCol'+i]);
                        document.getElementById('r'+i+'StalkL').setAttributeNS(null, "x1", this['r'+i+'StalkLx']);
                        document.getElementById('r'+i+'StalkL').setAttributeNS(null, "x2", this['r'+i+'StalkLx']);
                        document.getElementById('r'+i+'StalkR').setAttributeNS(null, "x1", this['r'+i+'StalkRx']);
                        document.getElementById('r'+i+'StalkR').setAttributeNS(null, "x2", this['r'+i+'StalkRx']);
                        this['r'+i+'RectW'] = (this['r'+i+'StalkRx']) - (this['r'+i+'StalkLx']);
                        document.getElementById('r'+i+'Rect').setAttributeNS(null, "x", this['r'+i+'StalkLx']);
                        document.getElementById('r'+i+'Rect').setAttributeNS(null, "width", this['r'+i+'RectW']);
                        if(!this['r'+i+'Name']){this['r'+i+'Name'] = this['r'+i+'Idx']}
                        document.getElementById('r'+i+'Name').textContent = this['r'+i+'Name'];
                        document.getElementById('r'+i+'Name').setAttributeNS(null, "fill", lumaOffset(this['rCol'+i]));
                        this['r'+i+'NamePos'] = this['r'+i+'StalkLx'] + ((this['r'+i+'StalkRx']-this['r'+i+'StalkLx'])/2);
                        document.getElementById('r'+i+'Name').setAttributeNS(null, "transform", "matrix(1 0 0 1 "+this['r'+i+'NamePos']+" 31)");
                        }
                    else{document.getElementById('region'+i).setAttributeNS(null, "visibility", "hidden");}
                    }

                if(mrMapAr[prevl] && mrMapAr[prevl][1]>=1){
                    var mPrevIdx = mrMapAr[prevl][1];
                    //~ if (!timesel_points.includes(null)) {
                        //~ if (timesel_points.includes(Number(mPrevIdx))) { select_points.push("prev"); }
                    //~ }
                    if (!markerDeletePending["marker1"]) {
                        var mPrevName = getValFromAr(g_markers,mPrevIdx,2,1);
                        var mPrevCol = getValFromAr(g_markers,mPrevIdx,2,4);
                        mPrevCol = "#" + (mPrevCol|0x1000000).toString(16).substr(-6);
                        document.getElementById("marker1").setAttributeNS(null, "visibility", "visible");
                        document.getElementById("marker1Bg").setAttributeNS(null, "fill", mPrevCol);
                        document.getElementById("marker1Number").textContent = mPrevIdx;
                        document.getElementById("marker1Number").setAttributeNS(null, "fill", lumaOffset(mPrevCol));
                        document.getElementById("prevMarkerName").textContent = (!mPrevName) ?("unnamed"):(mPrevName);
                    }
                }
                else{document.getElementById("marker1").setAttributeNS(null, "visibility", "hidden");}
                if(mrMapAr[thisl] && mrMapAr[thisl][1]>=1){
                    var mThisIdx = mrMapAr[thisl][1];
                    //~ if (!timesel_points.includes(null)) {
                        //~ console.log("does",timesel_points,"include",mThisIdx);
                        //~ console.log(4.0 == 4);
                        //~ if (timesel_points.includes(Number(mThisIdx))) { select_points.push("same"); }
                    //~ }
                    if (!markerDeletePending["marker2"]) {
                        var mThisName = getValFromAr(g_markers,mThisIdx,2,1);
                        var mThisCol = getValFromAr(g_markers,mThisIdx,2,4);
                        mThisCol = "#" + (mThisCol|0x1000000).toString(16).substr(-6);
                        document.getElementById("marker2").setAttributeNS(null, "visibility", "visible");
                        document.getElementById("marker2Bg").setAttributeNS(null, "fill", mThisCol);
                        document.getElementById("marker2Number").textContent = mThisIdx ;
                        document.getElementById("marker2Number").setAttributeNS(null, "fill", lumaOffset(mThisCol));
                        document.getElementById("atMarkerName").textContent = (!mThisName) ?("unnamed"):(mThisName);
                    }
                }
                else{document.getElementById("marker2").setAttributeNS(null, "visibility", "hidden");}

                if(mrMapAr[nextl] && mrMapAr[nextl][1]>=1){
                    var mNextIdx = mrMapAr[nextl][1];
                    //~ if (!timesel_points.includes(null)) {
                        //~ if (timesel_points.includes(Number(mNextIdx))) { select_points.push("next"); }
                    //~ }
                    if (!markerDeletePending["marker3"]) {
                        var mNextName = getValFromAr(g_markers,mNextIdx,2,1);
                        var mNextCol = getValFromAr(g_markers,mNextIdx,2,4);
                        mNextCol = "#" + (mNextCol|0x1000000).toString(16).substr(-6);
                        document.getElementById("marker3").setAttributeNS(null, "visibility", "visible");
                        document.getElementById("marker3Bg").setAttributeNS(null, "fill", mNextCol);
                        document.getElementById("marker3Number").textContent = mNextIdx ;
                        document.getElementById("marker3Number").setAttributeNS(null, "fill", lumaOffset(mNextCol));
                        document.getElementById("nextMarkerName").textContent = (!mNextName) ?("unnamed"):(mNextName);
                    }
                }
                else{document.getElementById("marker3").setAttributeNS(null, "visibility", "hidden");}

                if (prevl>=0){homeIconVis = "hidden"; prevIconVis = "visible";}
                    else {
                        homeIconVis = "visible"; prevIconVis = "hidden";
                        if (pos>0){
                            document.getElementById("marker1").setAttributeNS(null, "visibility", "visible");
                            document.getElementById("prevMarkerName").textContent = "HOME";
                            if (!timesel_points.includes(null)) {
                                if (timesel_points.includes("home")) { select_points.push("prev"); }
                            }
                            document.getElementById("marker1Number").textContent = "H";
                            document.getElementById("marker1Bg").setAttributeNS(null, "fill", "#1a1a1a");
                            document.getElementById("marker1Number").setAttributeNS(null, "fill", "#A8A8A8");
                            }
                        else{
                            document.getElementById("marker2").setAttributeNS(null, "visibility", "visible");
                            document.getElementById("atMarkerName").textContent = "HOME";
                            if (!timesel_points.includes(null)) {
                                if (timesel_points.includes("home")) { select_points.push("same"); }
                            }
                            document.getElementById("marker2Number").textContent = "H";
                            document.getElementById("marker2Bg").setAttributeNS(null, "fill", "#1a1a1a");
                            document.getElementById("marker2Number").setAttributeNS(null, "fill", "#A8A8A8");
                            }
                        }
                if (thisl<0 && pos!=0){elAttribute("dropMarker","visibility","visible")}
                else{elAttribute("dropMarker","visibility","hidden")}
                if (nextl>=0){
                    endIconVis = "hidden"; nextIconVis = "visible";
                    }
                else {
                    document.getElementById("marker3").setAttributeNS(null, "visibility", "visible");
                    document.getElementById("nextMarkerName").textContent = "END";
                    if (!timesel_points.includes(null)) {
                        if (timesel_points.includes("end")) { select_points.push("next") }
                    }
                    document.getElementById("marker3Number").textContent = "E";
                    document.getElementById("marker3Bg").setAttributeNS(null, "fill", "#1a1a1a");
                    document.getElementById("marker3Number").setAttributeNS(null, "fill", "#A8A8A8");
                    endIconVis = "visible"; nextIconVis = "hidden";
                    }
                elAttribute("iconPrev","visibility",prevIconVis);
                elAttribute("iconHome","visibility",homeIconVis);
                elAttribute("iconNext","visibility",nextIconVis);
                elAttribute("iconEnd","visibility",endIconVis);


                if (!timesel_points.includes(null) && select_points.length < 2) {
                    if (timesel_points.includes("end") && mrMapAr.length > 0 && pos < mrMapAr[mrMapAr.length-1][0]) {
                        select_points.push("rightEdge");
                    }
                    if (timesel_points.includes("home") && mrMapAr[0] && pos > mrMapAr[0][0]) {
                        select_points.push("leftEdge");
                    }
                    if (select_points.length < 2) {
                        var inc = 0;
                        for(const [time,idx] of mrMapAr) {
                            if (timesel_points.includes(Number(idx))) {
                                if(mrMapAr[inc+1] && pos > mrMapAr[inc+1][0]) {
                                    select_points.push("leftEdge");
                                } else if (pos > mrMapAr[inc][0]) {
                                    select_points.push("prev");
                                } else if (pos == mrMapAr[inc][0]) {
                                    select_points.push("same");
                                } else if (mrMapAr[inc-1] && pos < mrMapAr[inc-1][0]) {
                                    select_points.push("rightEdge");
                                } else if (pos < mrMapAr[inc][0]) {
                                    select_points.push("next");
                                }
                            }
                            inc = inc+1;
                        }
                    }
                }
                newPos = pos;
                newMrMapLength = mrMapAr.length;
                lastMrMapStr = mrMapStr;
                updateTimeSelDisplay(select_points);
                }
        break;

        case "NTRACK":
            if (tok.length > 1) {nTrack = tok[1];}
        break;

     case "TRACK":
        idx = parseInt(tok[1]);
        if (tok.length > 5) {
            var backLoaded = document.getElementById("backLoad");
            var allTracksDiv = document.getElementById("tracks");
            var trackFound = document.getElementById("track" + tok[1]);

            if (!trackFound) {
                var trackDiv = document.createElement("div");
                    trackDiv.id = ("track" + tok[1]);
                    trackDiv.className = ("trackDiv");

                trackHeightsAr[tok[1]] = 0;

                var trackRow1Div = document.createElement("div");
                    trackRow1Div.className = ("trackRow1");
                var trackRow2Div = document.createElement("div");
                    trackRow2Div.className = ("trackRow2");
                    trackRow2Div.id = tok[1];
                var trackSendsDiv = document.createElement("div");
                    trackSendsDiv.id = ("sendsTrack" + idx);

                if(trackDiv && allTracksDiv){allTracksDiv.appendChild(trackDiv);}
                    trackDiv.appendChild(trackRow1Div) ;
                    trackDiv.appendChild(trackRow2Div) ;
                    trackDiv.appendChild(trackSendsDiv);
            }

            else {
                if(backLoaded!=null && backLoaded.nextSibling!=null){
                    var cloneTrackRow1 = document.getElementById("trackRow1Svg").cloneNode(true);
                    var cloneTrackRow2 = document.getElementById("trackRow2Svg").cloneNode(true);
                    var cloneTrackSend = document.getElementById("trackSendSvg").cloneNode(true);

                    if(idx==0){ //master track stuff

                            masterMuteOffButton = document.getElementById("master-mute-off");
                            masterMuteOnButton = document.getElementById("master-mute-on");
                                if(tok[3]&8){masterMuteOffButton.style.visibility = "hidden"; masterMuteOnButton.style.visibility = "visible";}
                                else{masterMuteOffButton.style.visibility = "visible"; masterMuteOnButton.style.visibility = "hidden";}
                            masterMuteOffButton.onmousedown = mouseDownEventHandler("SET/TRACK/" + 0 + "/MUTE/-1;TRACK/" + 0);
                            masterMuteOnButton.onmousedown = mouseDownEventHandler("SET/TRACK/" + 0 + "/MUTE/-1;TRACK/" + 0);
                            masterClipIndicator = document.getElementById("master-clip_on");
                                if(tok[6]>0){masterClipIndicator.style.visibility = "visible";}
                                else{masterClipIndicator.style.visibility = "hidden";}
                            masterMeterReadout = document.getElementById("masterDb");
                            masterMeterReadout.textContent = (mkvolstr(tok[4]));

                            var masterTrackContent = document.getElementById("track0");
                            var masterTrackRow2Content = masterTrackContent.childNodes[3];
                            if (!masterTrackRow2Content.innerHTML){
                                masterTrackRow2Content.appendChild(cloneTrackRow2);
                                var trackSendsDiv = document.createElement("div");
                                trackSendsDiv.id = ("sendsTrack0");
                                masterTrackContent.appendChild(trackSendsDiv);
                                }

                            var volThumb = masterTrackRow2Content.getElementsByClassName("fader")[0];
                            if(faderConAr[0]!=1){
                                volFaderConect(masterTrackRow2Content,volThumb);
                                faderConAr[0]=1;
                                }
                            volThumb.volSetting = (Math.pow(tok[4], 1/4) * 194.68);
                            var vteMove = "translate(" + volThumb.volSetting + " 0)";
                            if(mouseDown != 1){volThumb.setAttributeNS(null, "transform", vteMove);}

                            var masterSends = tok[12];
                            if(masterSends!=trackSendCntAr[0]){
                                trackSendCntAr[0] = masterSends;
                                }
                            }

                    if(idx>0){ //normal track stuff

                        var trackRow1Content = document.getElementById("track" + idx).childNodes[0];
                        if (!trackRow1Content.innerHTML){
                            trackRow1Content.appendChild(cloneTrackRow1);
                            trackRow1Content.firstChild.getElementsByClassName("hitbox")[0].id = idx;
                            var nameHitbox = trackRow1Content.firstChild.getElementsByClassName("nameHitbox")[0];
                            (function(capturedIdx) {
                                var nameHitbox = trackRow1Content.firstChild.getElementsByClassName("nameHitbox")[0];
                                var trackNumHitbox = trackRow1Content.firstChild.getElementsByClassName("trackNumHitbox")[0];
                                nameHitbox.addEventListener("click", function(e) {
                                    e.stopPropagation();
                                    var trackNameEl = trackRow1Content.firstChild.getElementsByClassName("trackName")[0];
                                    var currentName = trackNamesAr[capturedIdx] || "";

                                    function commit() {
                                        var newName = prompt("Rename track",currentName);
                                        if (newName !== null && newName !== currentName) {
                                            wwr_req(40297);
                                            wwr_req("SET/TRACK/" + capturedIdx + "/SEL/1");
                                            wwr_req("SET/EXTSTATE/Fanciest/TrackRename/" + newName);
                                            wwr_req("_RSee5f76504d47c5481f6b7b49fb19603bfdd9c4e3");// rename track from extstate lua command
                                            wwr_req("_SWSAUTOCOLOR_APPLY");
                                        }
                                    }
                                    commit();
                                });
                                trackNumHitbox.addEventListener("click", function(e) {
                                    e.stopPropagation();

                                    function commit() {
                                        var newOrder = Math.min(100, Math.max(1, parseInt(prompt("Reorder track",capturedIdx), idx)));
                                        if (newOrder !== capturedIdx && typeof(newOrder) !== "string") {
                                            wwr_req(40297);
                                            wwr_req("SET/TRACK/" + capturedIdx + "/SEL/1");
                                            var command = "";
                                            if ((newOrder - capturedIdx) < 0) {
                                                for (let i = 0; i < (capturedIdx - newOrder - 1); i++) {
                                                    command += "43647;";
                                                }
                                                command += "43647"
                                            } else if ((capturedIdx - newOrder) < 0) {
                                                for (let i = 0; i < (newOrder - capturedIdx - 1); i++) {
                                                    command += "43648;";
                                                }
                                                command += "43648"
                                            }
                                            wwr_req(command);
                                        }
                                    }
                                    commit();
                                });
                            })(idx);
                            }

                        var trackRow2Content = document.getElementById("track" + idx).childNodes[1];
                        if (!trackRow2Content.innerHTML){
                            trackRow2Content.appendChild(cloneTrackRow2);
                            }

                        trackBg = trackRow1Content.firstChild.getElementsByClassName("trackrow1bg")[0];
                        if(tok[13]>0 && tok[13]!=trackColoursAr[idx]){
                            var customTrackColour = ("#" + (tok[13]|0x1000000).toString(16).substr(-6));
                            trackBg.style.fill= customTrackColour;
                            trackColoursAr[idx] = tok[1];
                            }
                            else{trackBg.style.fill= "#9DA5A5";}

                        if(tok[1]!=trackNumbersAr[idx]){
                            trackNumber = trackRow1Content.firstChild.getElementsByClassName("trackNumber")[0];
                            trackNumber.textContent = tok[1];
                            trackNumbersAr[idx] = tok[1];
                            }

                        if(tok[2]!=trackNamesAr[idx]){
                            trackText = trackRow1Content.firstChild.getElementsByClassName("trackName")[0];
                            trackText.textContent = tok[2];
                            trackNamesAr[idx] = tok[2];
                            }

                        var recCycleInProgress = false;



                        trackRow1Content.firstChild.getElementsByClassName("mute")[0].onmousedown = mouseDownEventHandler("SET/TRACK/" + tok[1] + "/MUTE/-1;TRACK/" + tok[1]);
                        trackRow1Content.firstChild.getElementsByClassName("solo")[0].onmousedown = mouseDownEventHandler("SET/TRACK/" +idx+ "/SOLO/-1;TRACK/" +idx);
                        trackRow1Content.firstChild.getElementsByClassName("monitor")[0].onmousedown = mouseDownEventHandler("SET/TRACK/" + idx + "/RECMON/-1;TRACK/" + idx);
                        if(tok[3]!=trackFlagsAr[idx]){

                            //~ recarmOffButton = trackRow1Content.firstChild.getElementsByClassName("recarm-off")[0];
                            //~ recarmOnButton = trackRow1Content.firstChild.getElementsByClassName("recarm-on")[0];
                            //~ if(tok[3]&64){recarmOffButton.style.visibility = "hidden"; recarmOnButton.style.visibility = "visible";}
                            //~ else{recarmOffButton.style.visibility = "visible"; recarmOnButton.style.visibility = "hidden";}
                            //~ recarmOffButton  = trackRow1Content.firstChild.getElementsByClassName("recarm-off")[0];
                            //~ recarmOnButton   = trackRow1Content.firstChild.getElementsByClassName("recarm-on")[0];
                            //~ recarmOn2Button  = trackRow1Content.firstChild.getElementsByClassName("recarm-on2")[0];
                            //~ var isArmed      = tok[3]&64;
                            //~ var isCh2        = isArmed && (trackArmChannelAr[idx] == 2);
                            //~ recarmOffButton.style.visibility  = isArmed ? "hidden"  : "visible";
                            //~ recarmOnButton.style.visibility   = (isArmed && !isCh2) ? "visible" : "hidden";
                            //~ recarmOn2Button.style.visibility  = isCh2 ? "visible" : "hidden";

                            soloOffButton = trackRow1Content.firstChild.getElementsByClassName("solo-off")[0];
                            soloOnButton = trackRow1Content.firstChild.getElementsByClassName("solo-on")[0];
                            if(tok[3]&16){soloOffButton.style.visibility = "hidden"; soloOnButton.style.visibility = "visible";}
                            else{soloOffButton.style.visibility = "visible"; soloOnButton.style.visibility = "hidden";}

                            muteOffButton = trackRow1Content.firstChild.getElementsByClassName("mute-off")[0];
                            muteOnButton = trackRow1Content.firstChild.getElementsByClassName("mute-on")[0];
                            if(tok[3]&64){muteOffButton.style.visibility = "hidden"; muteOnButton.style.visibility = "hidden";}
                            else{ if(tok[3]&8){muteOffButton.style.visibility = "hidden"; muteOnButton.style.visibility = "visible";}
                                else{muteOffButton.style.visibility = "visible"; muteOnButton.style.visibility = "hidden";}}

                            monitorOffButton = trackRow1Content.firstChild.getElementsByClassName("monitor-off")[0];
                            monitorOnButton = trackRow1Content.firstChild.getElementsByClassName("monitor-on")[0];
                            monitorAutoButton = trackRow1Content.firstChild.getElementsByClassName("monitor-auto")[0];
                            if(tok[3]&64){
                                if(tok[3]&128){monitorOffButton.style.visibility = "hidden"; monitorOnButton.style.visibility = "visible"; monitorAutoButton.style.visibility = "hidden";}
                                else{   if(tok[3]&256){monitorOffButton.style.visibility = "hidden"; monitorOnButton.style.visibility = "hidden"; monitorAutoButton.style.visibility = "visible";}
                                        else{monitorOffButton.style.visibility = "visible"; monitorOnButton.style.visibility = "hidden"; monitorAutoButton.style.visibility = "hidden";}
                                    }
                                }
                            else{monitorOffButton.style.visibility = "hidden"; monitorOnButton.style.visibility = "hidden"; monitorAutoButton.style.visibility = "hidden";}

                        if(tok[3]&512){ //track hidden in TCP
                            document.getElementById("track" + idx).style.display="none";}
                        else{document.getElementById("track" + idx).style.display = "block";}

                        folderIcon = trackRow1Content.firstChild.getElementsByClassName("folder_icon")[0];
                        if(tok[3]&1){folderIcon.style.visibility = "visible";}
                            else{folderIcon.style.visibility = "hidden";}
                            trackFlagsAr[idx] = tok[3];
                            }

                        if(tok[10]!=trackSendCntAr[idx]){
                            sendIndicator = trackRow1Content.firstChild.getElementsByClassName("s_on")[0];
                            if(tok[10]>0){sendIndicator.style.visibility = "visible";}
                            else{sendIndicator.style.visibility = "hidden";}
                            trackSendCntAr[idx] = tok[10];
                            }

                        if(tok[11]!=trackRcvCntAr[idx]){
                            rcvIndicator = trackRow1Content.firstChild.getElementsByClassName("r_on")[0];
                            if(tok[11]>0){rcvIndicator.style.visibility = "visible";}
                            else{rcvIndicator.style.visibility = "hidden";}
                            trackRcvCntAr[idx] = tok[11];
                            }

                        if(tok[12]!=trackHwOutCntAr[idx]){
                            sendIndicator = trackRow1Content.firstChild.getElementsByClassName("s_on")[0];
                            if(tok[12]>0){sendIndicator.style.visibility = "visible";}
                            trackHwOutCntAr[idx] = tok[12];
                            }

                        if(tok[6]!=trackPeakAr[idx]){
                            clipIndicator = trackRow1Content.firstChild.getElementsByClassName("clip_on")[0];
                            if(tok[6]>=0){clipIndicator.style.visibility = "visible";}
                            else{clipIndicator.style.visibility = "hidden";}

                            // cool idea but way too jittery to be tolerable
                            //~ var vuBar = trackRow1Content.firstChild.getElementsByClassName("vuBar")[0];
                            //~ if(vuBar) {
                                //~ // convert linear to dB, map -60dB..0dB to 0..33px
                                //~ var peak = tok[6];
                                //~ var barWidth = 0;
                                //~ if (typeof(time) !== "undefined") {
                                    //~ console.log(Date.now()-time);
                                    //~ time = Date.now();
                                //~ } else {
                                    //~ time = Date.now();
                                //~ }
                                //~ barWidth = Math.max(0, Math.min(33, (peak/600+1) * 33));
                                //~ barWidth = Math.round( barWidth );
                                //~ //console.log((peak/600+1) * 33);
                                //~ vuBar.setAttributeNS(null, "width", barWidth);
                            //~ }

                            trackPeakAr[idx] = tok[6];
                            }

                        meterReadout = trackRow1Content.firstChild.getElementsByClassName("meterReadout")[0];
                        meterReadout.textContent = (mkvolstr(tok[4]));

                        if (tok[3]&64) {recarmCountAr[idx]=1} else{recarmCountAr[idx]=0}
                            function getSum(total, num) {return total + num;}
                            var armedCount = document.getElementById("armed_count");
                            var armedText = document.getElementById("armed_text");
                            recarmCount = recarmCountAr.reduce(getSum);
                            armedCount.textContent = recarmCount;
                            armedCount.setAttributeNS(null, "fill", ((recarmCount==0)?"#5D3729":"#545454"));
                            armedText.setAttributeNS(null, "fill", ((recarmCount==0)?"#5D3729":"#545454"));

                        var volThumb = trackRow2Content.firstChild.getElementsByClassName("fader")[0];
                        if(faderConAr[idx]!=1){
                            volFaderConect(trackRow2Content,volThumb);
                            panKnobConnect(trackRow2Content, idx);
                            trackDeleteConnect(trackRow2Content, idx);
                            (function(capturedIdx) {
                                trackRow1Content.firstChild.getElementsByClassName("recarm")[0].addEventListener("click", async function(e) {
                                    if (recCycleInProgress[capturedIdx]) return;
                                    recCycleInProgress[capturedIdx] = true;
                                    try {
                                        var result = await requestRecCycle(capturedIdx);
                                        var row1 = document.getElementById("track" + capturedIdx).childNodes[0];
                                        var bg    = row1.getElementsByClassName("recarmBg")[0];
                                        var label = row1.getElementsByClassName("recarmLabel")[0];

                                        if (result == "off") {
                                            bg.setAttribute("fill", "#5D3729");
                                            label.textContent = "";
                                        } else if (result == "chan1") {
                                            bg.setAttribute("fill", "#FF2200");
                                            label.textContent = "1";
                                        } else if (result == "chan2") {
                                            bg.setAttribute("fill", "#FF6600");
                                            label.textContent = "2";
                                        }
                                        //console.log("record arm cycled:", result);
                                    } catch(e) {
                                        console.log("failed:", e);
                                    } finally {
                                        recCycleInProgress[capturedIdx] = false;
                                    }
                                });
                            })(idx);
                            faderConAr[idx]=1;
                            }
                        volThumb.volSetting = (Math.pow(tok[4], 1/4) * (194.68-40-14)) + 40; //40 = pan knob width
                        var vteMove = "translate(" + volThumb.volSetting + " 0)";
                        if(mouseDown != 1){volThumb.setAttributeNS(null, "transform", vteMove);}

                        // --- pan knob update ---
                        var panVal = parseFloat(tok[5]); // tok[5] is pan, -1 to +1
                        if(!isNaN(panVal) && trackPanAr[idx] != panVal) {
                            trackPanAr[idx] = panVal;
                            var panLine = trackRow2Content.firstChild.getElementsByClassName("panLine")[0];
                            if(panLine) {
                                var panAngle = panVal * 135; // -135 to +135 degrees
                                panLine.setAttribute("transform", "rotate(" + panAngle + " 20 18)");
                            }
                        }
                    }
                    var trackSendsContent = document.getElementById("sendsTrack" + idx);
                    trackSendHwCntAr[idx] = (parseInt(trackSendCntAr[idx]) || 0) + (parseInt(trackHwOutCntAr[idx]) || 0);
                        if(trackSendsContent!=null && trackSendHwCntAr[idx]!=null){
                            if(trackSendsContent.childNodes.length < trackSendHwCntAr[idx]){
                                    var sendDiv = document.createElement("div");
                                    sendDiv.className = ("sendDiv");
                                    trackSendsContent.appendChild(sendDiv);
                                        sendDiv.appendChild(cloneTrackSend);
                                    var thisSendThumb = sendDiv.getElementsByClassName("sendThumb")[0];
                                    sendConect(sendDiv,thisSendThumb);
                                    //bug - adding a send doesn't update the height of that send. So it'll be zero even if the panel is expanded.
                                }
                            if(trackSendsContent.childNodes.length >trackSendHwCntAr[idx]){
                                trackSendsContent.removeChild(trackSendsContent.firstChild);
                                }
                            }
                }
            }

            var tracksDiv = document.getElementById('tracks');
            if (tracksDiv!=null){
                var tracksDrawnIncMaster = tracksDiv.childNodes;
                var tracksDrawn = (tracksDrawnIncMaster.length - 1);
                }
            if (tracksDrawn > nTrack) {
                tracks.removeChild(tracks.lastChild);
                }
      }
    break;

    case "SEND":
        function sendConect(content, thumb){
            content.addEventListener("mousemove", sendMouseMoveHandler, false);
            content.addEventListener("touchmove", sendMouseMoveHandler, false);
            content.addEventListener("mouseleave", mouseLeaveHandler, false);
            content.addEventListener("mouseup", sendMouseUpHandler, false);
            content.addEventListener("touchend", sendMouseUpHandler, false);
            thumb.addEventListener("mousedown", function (event) {mouseDownHandler(event, event.srcElement)}, false);
            thumb.addEventListener('touchstart', function(event){
                if (event.touches.length > 0) mouseDownHandler(event, event.srcElement);
                event.preventDefault(); }, false);
            }

        if (tok.length > 3) {
            var targetName;
                if(tok[6]>0) targetName = trackNamesAr[tok[6]];
                else targetName = "Hardware";
            var sendMuted = ", not muted";
            if(tok[3]&8) sendMuted = ", MUTED";

            var trackSendsContent = document.getElementById("sendsTrack" + tok[1]);
            if(trackSendsContent.childNodes.length>0){
                var thisSendDiv = trackSendsContent.childNodes[tok[2]];
                if(thisSendDiv!=null){
                    thisSendDiv.id=[tok[2]];
                    sendTitleText = thisSendDiv.firstChild.getElementsByClassName("sendTitleText")[0];
                    if(sendTitleText.textContent!=targetName)sendTitleText.textContent = targetName;
                    sDbText = thisSendDiv.firstChild.getElementsByClassName("sDbText")[0];
                    sDbValue = mkvolstr(tok[4])
                    if(sDbText.Content!=sDbValue)sDbText.textContent = sDbValue;

                    var sendLine = thisSendDiv.firstChild.getElementsByClassName("sendLine")[0];
                    sLineSetting = (Math.pow(tok[4], 1/4) * 154) + 27;
                    if(mouseDown != 1){sendLine.setAttributeNS(null, "x2", sLineSetting);}

                    var sendThumb = thisSendDiv.firstChild.getElementsByClassName("sendThumb")[0];
                    if(tok[6]>0){
                        var sendTargetBg = document.getElementsByClassName("trackrow1bg")[(tok[6]-1)]
                        if(sendTargetBg!=undefined){var sendTargetBgColour = (sendTargetBg.getAttribute("style"))}
                        var sendThumbColour = sendThumb.getAttribute("style")
                        var defaultColour = "fill: rgb(157, 165, 165);";
                        if(sendTargetBgColour!=defaultColour){
                            if(sendThumbColour!=sendTargetBgColour){
                                sendThumb.setAttributeNS(null, "style", sendTargetBgColour);
                                sendTitleText.setAttributeNS(null, "style", sendTargetBgColour);
                                sendThumb.setAttributeNS(null, "opacity", "0.5");
                                }
                            }
                            else{
                                sendThumb.setAttributeNS(null, "style", "none");
                                sendTitleText.setAttributeNS(null, "style", "none");
                                sendThumb.setAttributeNS(null, "opacity", "0.5");
                                }
                        }

                    sThumbSetting = (Math.pow(tok[4], 1/4) * 154) + 27;
                    if(mouseDown != 1){sendThumb.setAttributeNS(null, "cx", sThumbSetting);}

                    var sendMuteButton = thisSendDiv.firstChild.getElementsByClassName("send_mute")[0];
                    sendMuteButton.onmousedown = mouseDownEventHandler("SET/TRACK/" + tok[1] + "/SEND/" + tok[2] + "/MUTE/-1");
                    var sendMuteOff = thisSendDiv.firstChild.getElementsByClassName("send_mute_off")[0];
                    var sendMuteOn = thisSendDiv.firstChild.getElementsByClassName("send_mute_on")[0];
                    if(tok[3]&8){
                        sendMuteOff.style.visibility = "hidden";
                        sendMuteOn.style.visibility = "visible";
                        }
                    else{
                        sendMuteOff.style.visibility = "visible";
                        sendMuteOn.style.visibility = "hidden";
                        }
                    }
                }
            }
    }
  }
    if(trackSendHwCntAr.length>0){
        for(x=0;x<trackSendHwCntAr.length;x++){
            if(trackSendHwCntAr[x]>0){
                for(y=0;y<trackSendHwCntAr[x];y++){
                wwr_req("GET/TRACK/" + x + "/SEND/" + y);
                    }
                }
            }
        }
    wwr_listeners.forEach(function(fn) {fn(results); });
}

function updateProjectName() {
    var done = [false, false, false];
    function listener(results) {
        if (done[0] && done [1] && done[2]) return;
        var ar = results.split("\n");
        for (var i = 0; i < ar.length; i++) {
            var tok = ar[i].split("\t");
            if (tok[0] == "EXTSTATE" && tok[1] == "Fanciest" && tok[2] == "CurrentProject") {
                done[0] = true;
                wwr_listeners = wwr_listeners.filter(function(f) { return f !== listener; });
                var el = document.getElementById("projectNameDisplay");
                if (tok[3]) name = tok[3];
                else name = "unsaved";
                if (el) el.textContent = name;
            } else if (tok[0] == "EXTSTATE" && tok[1] == "Fanciest" && tok[2] == "SelectDisplay") {
                done[1] = true;
                timesel_points = [];
                if ( tok[3]=="none" ) {
                    timesel_points.push(null);
                } else {
                    sel = tok[3].split(":");
                    if (first = Number(sel[0])) {
                        timesel_points.push(first);
                    } else {
                        timesel_points.push(sel[0]);
                    }
                    if (second = Number(sel[1])) {
                        timesel_points.push(second);
                    } else {
                        timesel_points.push(sel[1]);
                    }
                    wwr_req("REGION");
                }
            } else if (tok[0] == "EXTSTATE" && tok[1] == "Fanciest" && tok[2] == "ArmDisplay") {
                done[2] = true;
                if (tok[3] != '') {
                    armStates = tok[3].split(":");
                    for (var t = 0; t<armStates.length; t++) {
                        var row1 = document.getElementById("track" + (t+1)).childNodes[0];
                        var bg    = row1.getElementsByClassName("recarmBg")[0];
                        var label = row1.getElementsByClassName("recarmLabel")[0];
                        var result = armStates[t];

                        if (result == "off") {
                            bg.setAttribute("fill", "#5D3729");
                            label.textContent = "";
                        } else if (result == "chan1") {
                            bg.setAttribute("fill", "#FF2200");
                            label.textContent = "1";
                        } else if (result == "chan2") {
                            bg.setAttribute("fill", "#FF6600");
                            label.textContent = "2";
                        }
                    }
                }
            }
        }
    };
    wwr_listeners.push(listener);
    wwr_req("_RS4c27663790d92e7417a89841eba29e9edff7d90d"); // get current project name
    setTimeout(function() {
        wwr_req("GET/EXTSTATE/Fanciest/CurrentProject");
        wwr_req("GET/EXTSTATE/Fanciest/SelectDisplay");
        wwr_req("GET/EXTSTATE/Fanciest/ArmDisplay");
    }, 300);
}

function updateTempo() {
    var done = false;
    function listener(results) {
        if (done) return;
        var ar = results.split("\n");
        for (var i = 0; i < ar.length; i++) {
            var tok = ar[i].split("\t");
            if (tok[0] == "EXTSTATE" && tok[1] == "Fanciest" && tok[2] == "CurrentTempo") {
                done = true;
                wwr_listeners = wwr_listeners.filter(function(f) { return f !== listener; });
                if (tok[3]) currentTempo = Number(tok[3]);
            }
        }
    };
    wwr_listeners.push(listener);
    wwr_req("_RSeb2bd4bbe2ec2d617ffb189cc03dfc62120c7f86"); // get current project tempo
    setTimeout(function() {
        wwr_req("GET/EXTSTATE/Fanciest/CurrentTempo");
    }, 300);
}

function on_record_button(e) {
  if (recarmCount > 0 || confirm("no tracks are armed, start record?")) wwr_req(1013);
  return false;
}

function prompt_abort() {
  if (!(last_transport_state&4)) {
    wwr_req(1016);
  } else {
    if (confirm("abort recording? contents will be lost!")) wwr_req(40668);
  }
}

function prompt_seek() {
  if (!(last_transport_state&4)) {
    var seekto = prompt("Seek to position:",last_time_str);
    if (seekto != null) {
      wwr_req("SET/POS_STR/" + encodeURIComponent(seekto));
    }
  }
}

var scaleFactor = 1, optionsOpen =0;

function calculateScale(event) {
    var a = document.getElementById("transport_r2");
    if(a){var drawnWidth = a.clientWidth;}
    else{drawnWidth = 303.6}
    scaleFactor = drawnWidth/303.6;

    if(optionsOpen==1){
            for (var i=0; i<hereCss.cssRules.length; i++){
                if(hereCss.cssRules[i].selectorText==".optionsBar"){
                    hereCss.deleteRule(i);
                    hereCss.insertRule(".optionsBar {height:"+(scaleFactor*88)+"px;}",i);
                    }
            }
        }

    document.getElementById("options").onclick = function(){
        if(optionsOpen!=1){
            for (var i=0; i<hereCss.cssRules.length; i++){
                if(hereCss.cssRules[i].selectorText==".optionsBar"){
                    hereCss.deleteRule(i);
                    hereCss.insertRule(".optionsBar {height:"+(scaleFactor*88)+"px;}",i);
                    }
                }
            optionsOpen=1;
            }
        else{
            for (var i=0; i<hereCss.cssRules.length; i++){
                if(hereCss.cssRules[i].selectorText==".optionsBar"){
                    hereCss.deleteRule(i);
                    hereCss.insertRule(".optionsBar {height:0px;}",i);
                    }
                }
            optionsOpen=0;
            }
        }
    }

window.addEventListener('resize', calculateScale, false);

trackHeightsAr[0] = 0;
function hitbox(id) {
    var thisTrackRow2 = document.getElementsByClassName("trackRow2")[id];
    var thisTrackRow2Svg = thisTrackRow2.firstChild.firstElementChild;
    var easingValue = 0;
    transitionTime = 10;

   if(trackHeightsAr[id]==0){
       iteration = 0;
       requestAnimationFrame(resizerDown);
       function resizerDown() {
            if(iteration<transitionTime){
                easingValue = easeInOutCubic(iteration, 0, 1, transitionTime);
                if(easingValue<=0.1){easingValue=0.01;}
                if(transitions==0){var row2scaleD = 37;}
                else{row2scaleD = easingValue * 37;}
                thisTrackRow2Svg.setAttributeNS(null, "viewBox", "0 1 320 " + row2scaleD);
                if(trackSendHwCntAr[id]>0){
                    if(transitions==0){var sendscaleD = 50;}
                    else{sendscaleD = easingValue * 50;}
                    for(x=0;x<trackSendHwCntAr[id];x++){
                        thisSendSvg = document.getElementById("sendsTrack"+[id]).childNodes[x].firstElementChild.firstElementChild;
                        thisSendSvg.setAttributeNS(null, "viewBox", "0 0 320 " + sendscaleD)
                        }
                    }
                iteration++;
                requestAnimationFrame(resizerDown);}
                }
        }
   else{
       iteration = 0;
       requestAnimationFrame(resizerUp);
       function resizerUp() {
            if(iteration<transitionTime){
                easingValue = easeInOutCubic(iteration, 1, -1, transitionTime);
                if(transitions==0){var row2scaleU = 0.01;}
                else{row2scaleU = easingValue * 37;}
                thisTrackRow2Svg.setAttributeNS(null, "viewBox", "0 0 320 " + row2scaleU);
                if(trackSendHwCntAr[id]>0){
                    if(transitions==0){var sendscaleU = 0.01;}
                    else{sendscaleU = easingValue * 50;}
                    for(x=0;x<trackSendHwCntAr[id];x++){
                        thisSendSvg = document.getElementById("sendsTrack"+[id]).childNodes[x].firstElementChild.firstElementChild;
                        thisSendSvg.setAttributeNS(null, "viewBox", "0 0 320 " + sendscaleU)
                        }
                    }
                iteration++;
                requestAnimationFrame(resizerUp);}
                }
        }
    trackHeightsAr[id] ^= 1;
    }

function init(){
  if (/iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream) {
    for (let l = 0; l < document.styleSheets.length; l ++) {
      let ss = document.styleSheets[l];
      if (ss.cssRules) for (let i=0; i < ss.cssRules.length; i++){
        let st = ss.cssRules[i].selectorText;
        if (st != undefined && st.startsWith(".button")) ss.removeRule(i--);
        transitions = 0;
        doTransitionButton();
      }
    }
  }
  updateProjectName();
  updateTempo();
}
</script>
</head>
<body onLoad="init();calculateScale()">
<div id="colWrap">
<div id="col1">
<div id="optionsBar" class="optionsBar">
    <div style="width:100%; background-color:#1a1a1a;">
    <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="100%" viewBox="0 0 320 38" xml:space="preserve">
        <rect width="320" height="38" fill="#1a1a1a"/>

        <!-- save button -->
        <g class="button" id="btnSave">
            <rect x="1" y="1" width="36" height="36" fill="#262626" rx="2"/>
            <rect class="active" visibility="hidden" x="1" y="1" width="36" height="36" fill="#8a9999" rx="2"/>
            <!-- floppy disk icon -->
            <rect x="8" y="7" width="22" height="24" rx="2" fill="#57FF86"/>
            <rect x="11" y="7" width="10" height="8" fill="#1a1a1a"/>
            <rect x="13" y="8" width="2" height="6" fill="#57FF86"/>
            <rect x="10" y="18" width="18" height="11" rx="1" fill="#1a1a1a"/>
            <rect x="12" y="20" width="14" height="7" rx="1" fill="#262626"/>
            <rect class="mouseover" visibility="hidden" x="1" y="1" width="36" height="36" opacity="0.05" fill="#FFFFFF" rx="2"/>
        </g>

        <!-- open button -->
        <g class="button" id="btnOpen">
            <rect x="40" y="1" width="36" height="36" fill="#262626" rx="2"/>
            <rect class="active" visibility="hidden" x="40" y="1" width="36" height="36" fill="#8a9999" rx="2"/>
            <!-- folder icon -->
            <path fill="#FFD057" d="M49,12h6l2,3h10c1,0,1,1,1,1v11c0,1-1,1-1,1H49c-1,0-1-1-1-1V13C48,12,49,12,49,12z"/>
            <path fill="#FFC020" d="M48,16h20l-2,12H48z"/>
            <rect class="mouseover" visibility="hidden" x="40" y="1" width="36" height="36" opacity="0.05" fill="#FFFFFF" rx="2"/>
        </g>

        <!-- project name display -->
        <text id="projectNameDisplay" x="84" y="24" fill="#808080" font-family="'Open Sans'" font-size="13px">No project</text>

    </svg>
    </div>
   <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="100%"
	viewBox="0 0 319 47" xml:space="preserve">
	<polygon fill="#1A1A1A" points="274.2,0 0.4,0 0.4,47 274.2,47 274.2,0 "/>
	<g class="button" onClick="wwr_req(40029)">>
		<rect class="iconBg" x="1.6" y="1.6" fill="#262626" width="43.9" height="43.9"/>
		<rect class="active" visibility="hidden" x="1.6" y="1.6" fill="#8a9999" width="43.9" height="43.9"/>
		<path id="iconUndo" fill="#FF5757" d="M19.3,30l2.2,4.6c-0.1,0.2-0.2,0.3-0.4,0.4v0.2c-0.1,0.1-0.6,0.3-0.6,0.4
			c0,0.1,0.1,0.3,0.1,0.4c-0.1,0.3-0.6,0.7-0.9,0.7c-0.4,0-0.9-1-1-1.2l-2.6-4L10.7,40c-0.3,0.2-1.1,0.3-1.4,0.3
			c-0.4,0-0.4-0.3-0.6-0.6c-0.2-0.2-0.4-0.6-0.4-0.9c0-0.2,0-0.3,0.1-0.4c0.1-0.2,0.2-0.4,0-0.6c-0.1-0.1-0.1-0.1-0.1-0.2
			c0-0.4,0.5-1,0.7-1.4l0.7-1.1c1.1-2,3.2-4.5,4.7-6.3l0.3-0.4l-2-5.6c-0.1-0.2-0.3-0.7-0.3-0.9c0-0.2,0.2-0.4,0.4-0.6l0.2-0.2
			c0.1-0.1,0.1-0.1,0.2-0.1c0.2,0,0.3,0.1,0.4,0.2c0.2-0.1,0.2-0.1,0.4-0.1c0.2-0.1,0.2-0.1,0.2-0.2c0.1-0.1,0.1-0.2,0.3-0.2
			c0.3,0,0.4,0.3,0.5,0.5l1.1,2.3l1,1.9l0.7-0.9l1.4-1.5c0.3-0.4,2.4-2.9,2.7-2.9c0.2,0,0.8,0.4,1,0.5l0.3-0.3
			c0.1-0.1,0.2-0.3,0.3-0.3c0.1,0,0.1,0.2,0.2,0.2c0.1,0.3,0.6,0.6,0.6,0.8c0,0.2-0.2,0.3-0.3,0.4c-0.3,0.3-0.7,0.8-0.9,1.1
			l-3.9,5.1l-0.3,0.4L19.3,30z M29.1,10.7H14.5V7.5L8,12.4l6.5,4.9V14h14.6c3.6,0,6.5,2.9,6.5,6.5c0,3.6-2.9,6.5-6.5,6.5h-4.9
			l-1.6,1.6l1.6,1.6h4.9c5.4,0,9.7-4.4,9.7-9.7C38.9,15.1,34.5,10.7,29.1,10.7z"/>
		<g class="gloss">
			<rect x="1.6" y="1.6" opacity="0.2" fill="#262626" width="43.9" height="43.9"/>
			<rect x="1.6" y="1.6" opacity="5.000000e-02" fill="#FFFFFF" width="43.9" height="21.9"/>
		</g>
		<rect class="mouseover" visibility="hidden" x="1.6" y="1.6" opacity="5.000000e-02" fill="#FFFFFF" width="43.9" height="43.9"/>
	</g>
	<g class="button" onClick="wwr_req(40030)">
		<rect class="iconBg" x="47" y="1.6" fill="#262626" width="43.9" height="43.9"/>
		<rect class="active" visibility="hidden" x="47" y="1.6" fill="#8a9999" width="43.9" height="43.9"/>
		<path id="iconRedo" fill="#57FF86" d="M69.9,21.8c1-1.1,3.1-1.6,4.5-1.6l0.2,0.4l-2.5,2.9l-5.5,7.3l-3.8,5.9l-0.9,1.6
			c-0.1,0.3-0.3,0.6-0.6,0.7c-0.3,0.2-1.1,0.2-1.5,0.2c-0.8,0-1,0-1.2-0.1c-0.3-0.2-0.4-0.6-0.6-0.9c-0.6-1.2-1.6-3.9-1.6-5.2
			c0-0.4,0.3-0.7,0.6-0.9c0.6-0.4,1.3-0.8,2-0.8c0.5,0,0.6,0.4,0.7,0.9l0.5,1.2c0.1,0.2,0.3,1,0.6,1c0.3,0,0.6-0.6,0.7-0.8l6.1-9.1
			L69.9,21.8z M69.3,29.8h9.1v-3.1h-6.7L69.3,29.8z M84.6,12.5l-6.3-4.7V11H64.2c-5.2,0-9.4,4.2-9.4,9.4c0,4.6,3.3,8.4,7.6,9.2l2-3
			h-0.2c-3.5,0-6.3-2.8-6.3-6.3c0-3.5,2.8-6.3,6.3-6.3h14.1v3.1L84.6,12.5z"/>
		<g class="gloss">
			<rect x="47" y="1.6" opacity="0.2" fill="#262626" width="43.9" height="43.9"/>
			<rect x="47" y="1.6" opacity="5.000000e-02" fill="#FFFFFF" width="43.9" height="21.9"/>
		</g>
		<rect class="mouseover" visibility="hidden" x="47" y="1.6" opacity="5.000000e-02" fill="#FFFFFF" width="43.9" height="43.9"/>
	</g>
	<g id="buttonMetro" class="button" onClick="wwr_req(40364)">
		<rect class="iconBg" x="92.4" y="1.6" fill="#262626" width="43.9" height="43.9"/>
		<rect class="active" visibility="hidden" x="92.4" y="1.6" fill="#8a9999" width="43.9" height="43.9"/>
		<g id="iconMetro">
			<polygon fill="#FFFFFF" points="117.5,9.4 112.8,9.4 110,17.8 110.9,21.3 114.2,11.4 114.4,12.5 115.9,12.5 116.1,11.4
				123.8,34.5 115.9,34.5 114.4,34.5 106.5,34.5 108.3,29.1 106.9,27 103.4,37.6 126.9,37.6 			"/>
			<polygon fill="#57FF86" points="115.5,34.5 108.4,23.5 109.7,22.7 108.4,17.9 105.8,19.6 100.6,11.5 99.2,12.3 104.5,20.4
				101.8,22.2 105.7,25.2 107.1,24.4 113.7,34.5 			"/>
		</g>
		<g class="gloss">
			<rect x="92.4" y="1.6" opacity="0.2" fill="#262626" width="43.9" height="43.9"/>
			<rect x="92.4" y="1.6" opacity="5.000000e-02" fill="#FFFFFF" width="43.9" height="21.9"/>
		</g>
		<rect class="mouseover" visibility="hidden" x="92.4" y="1.6" opacity="0.05" fill="#FFFFFF" width="43.9" height="43.9"/>
	</g>
	<!--<g class="button" onClick="wwr_req(40527)">
		<rect class="iconBg" x="183.3" y="1.6" fill="#262626" width="43.9" height="43.9"/>
		<rect class="active" visibility="hidden"  x="183.3" y="1.6" fill="#8a9999" width="43.9" height="43.9"/>
		<g id="iconClipClear">
			<path id="iconUndo_1_" fill="#FF5757" d="M208.6,14.5l2.2,4.6c-0.1,0.2-0.2,0.3-0.4,0.4v0.2c-0.1,0.1-0.6,0.3-0.6,0.4
				c0,0.1,0.1,0.3,0.1,0.4c-0.1,0.3-0.6,0.7-0.9,0.7c-0.4,0-0.9-1-1-1.2l-2.6-4l-5.5,8.5c-0.3,0.2-1.1,0.3-1.4,0.3
				c-0.4,0-0.4-0.3-0.6-0.6c-0.2-0.2-0.4-0.6-0.4-0.9c0-0.2,0-0.3,0.1-0.4c0.1-0.2,0.2-0.4,0-0.6c-0.1-0.1-0.1-0.1-0.1-0.2
				c0-0.4,0.5-1,0.7-1.4l0.7-1.1c1.1-2,3.2-4.5,4.7-6.3l0.3-0.4l-2-5.6c-0.1-0.2-0.3-0.7-0.3-0.9c0-0.2,0.2-0.4,0.4-0.6l0.2-0.2
				c0.1-0.1,0.1-0.1,0.2-0.1c0.2,0,0.3,0.1,0.4,0.2c0.2-0.1,0.2-0.1,0.4-0.1c0.2-0.1,0.2-0.1,0.2-0.2c0.1-0.1,0.1-0.2,0.3-0.2
				c0.3,0,0.4,0.3,0.5,0.5l1.1,2.3l1,1.9l0.7-0.9l1.4-1.5c0.3-0.4,2.4-2.9,2.7-2.9c0.2,0,0.8,0.4,1,0.5l0.3-0.3
				c0.1-0.1,0.2-0.3,0.3-0.3c0.1,0,0.1,0.2,0.2,0.2c0.1,0.3,0.6,0.6,0.6,0.8c0,0.2-0.2,0.3-0.3,0.4c-0.3,0.3-0.7,0.8-0.9,1.1
				l-3.9,5.1l-0.3,0.4L208.6,14.5z"/>
			<path fill="#922525" d="M195.3,41.3h19.8c3.7,0,6.6-3,6.6-6.6v-0.8c0-3.7-3-6.6-6.6-6.6h-19.8c-3.7,0-6.6,3-6.6,6.6v0.8
				C188.7,38.3,191.7,41.3,195.3,41.3z"/>
			<text transform="matrix(1 0 0 1 192.9692 38.471)" fill="#FFBFBF" font-family="'Open Sans'" font-size="11px">CLIP</text>
		</g>
		<g class="gloss">
			<rect x="183.3" y="1.6" opacity="0.2" fill="#262626" width="43.9" height="43.9"/>
			<rect x="183.3" y="1.6" opacity="5.000000e-02" fill="#FFFFFF" width="43.9" height="21.9"/>
		</g>
		<rect class="mouseover" visibility="hidden" x="183.3" y="1.6" opacity="5.000000e-02" fill="#FFFFFF" width="43.9" height="43.9"/>
	</g>-->
    <g id="buttonPreroll" class="button" onClick="wwr_req(41819)">
        <rect class="iconBg" x="183.3" y="1.6" fill="#262626" width="43.9" height="43.9"/>
        <rect id="prerollBg" x="183.3" y="1.6" opacity="0.2" fill="#262626" width="43.9" height="43.9"/>
        <rect class="active" visibility="hidden" x="183.3" y="1.6" fill="#8a9999" width="43.9" height="43.9"/>
        <!-- single teal icon always visible -->
        <line x1="205.3" y1="10" x2="205.3" y2="37" stroke="#57FF86" stroke-width="1.5" stroke-dasharray="3,2"/>
        <polygon fill="#57FF86" points="191,19 191,27 197,23"/>
        <line x1="188" y1="23" x2="191" y2="23" stroke="#57FF86" stroke-width="2"/>
        <polygon fill="#57FF86" points="198,19 198,27 204,23"/>
        <line x1="195" y1="23" x2="198" y2="23" stroke="#57FF86" stroke-width="2"/>
        <polygon fill="#57FF86" points="209,19 209,27 215,23"/>
        <line x1="206" y1="23" x2="209" y2="23" stroke="#57FF86" stroke-width="2"/>
        <g class="gloss">
            <rect x="183.3" y="1.6" opacity="0.2" fill="#262626" width="43.9" height="43.9"/>
            <rect x="183.3" y="1.6" opacity="5.000000e-02" fill="#FFFFFF" width="43.9" height="21.9"/>
        </g>
        <rect class="mouseover" visibility="hidden" x="183.3" y="1.6" opacity="5.000000e-02" fill="#FFFFFF" width="43.9" height="43.9"/>
    </g>
    <g id="buttonSnap" class="button" onClick="wwr_req(1157)">
		<rect class="iconBg" x="137.9" y="1.6" fill="#262626" width="43.9" height="43.9"/>
		<rect class="active" visibility="hidden" x="137.9" y="1.6" fill="#8a9999" width="43.9" height="43.9"/>
		<g id="iconSnap">
			<path fill="#57FF86" d="M159.8,11h-11v4.7h11c4.3,0,7.8,3.5,7.8,7.8s-3.5,7.8-7.8,7.8h-11V36h11c6.9,0,12.5-5.6,12.5-12.5
				S166.7,11,159.8,11z M153.5,14.1h-3.1v-1.6h3.1V14.1z M153.5,34.5h-3.1v-1.6h3.1V34.5z M144.1,7.8h1.6V11h-1.6V7.8z M144.1,15.7
				h1.6v-3.1h-1.6V15.7z M144.1,20.4h1.6v-3.1h-1.6V20.4z M144.1,25.1h1.6v-3.1h-1.6V25.1z M144.1,29.8h1.6v-3.1h-1.6V29.8z
				 M144.1,34.5h1.6v-3.1h-1.6V34.5z M144.1,39.2h1.6V36h-1.6V39.2z"/>
			<path fill="#ffffff" opacity="0.25" d="M169.2,11h-1.6V7.8h1.6V11z M168.5,12.5c0.2,0.2,0.5,0.4,0.7,0.6v-0.6H168.5z M152,37.5v1.6h1.6v-1.6H152
				z M161.4,9.6V7.8h-1.6v1.6C160.3,9.5,160.9,9.5,161.4,9.6z M153.5,9.5V7.8H152v1.6H153.5z M159.8,25.1h1.6v-3.1h-1.6V25.1z
				 M159.8,20.4h1.6v-3c-0.2-0.1-0.5-0.1-0.7-0.1h-0.9V20.4z M153.5,17.2H152v3.1h1.6V17.2z M152,29.8h1.6v-3.1H152V29.8z
				 M153.5,21.9H152v3.1h1.6V21.9z M161.4,26.6h-1.6v3.1h0.9c0.2,0,0.5-0.1,0.7-0.1V26.6z M175.5,25.1h1.6v-3.1h-1.6V25.1z
				 M175.5,29.8h1.6v-3.1h-1.6V29.8z M175.5,20.4h1.6v-3.1h-1.6V20.4z M175.5,15.7h1.6v-3.1h-1.6V15.7z M175.5,7.8V11h1.6V7.8H175.5
				z M175.5,34.5h1.6v-3.1h-1.6V34.5z M167.6,39.2h1.6V36h-1.6V39.2z M168.5,34.5h0.7v-0.6C169,34.1,168.8,34.3,168.5,34.5z
				 M175.5,39.2h1.6V36h-1.6V39.2z M159.8,37.5v1.6h1.6v-1.7C160.9,37.5,160.3,37.5,159.8,37.5z"/>
		</g>
		<g class="gloss">
			<rect x="137.9" y="1.6" opacity="0.2" fill="#262626" width="43.9" height="43.9"/>
			<rect x="137.9" y="1.6" opacity="5.000000e-02" fill="#FFFFFF" width="43.9" height="21.9"/>
		</g>
		<rect class="mouseover" visibility="hidden" x="137.9" y="1.6" opacity="5.000000e-02" fill="#FFFFFF" width="43.9" height="43.9"/>
	</g>
	<g id="transitionsButton" class="button">
		<rect class="iconBg" x="228.8" y="1.6" fill="#262626" width="43.9" height="43.9"/>
		<rect class="active" visibility="hidden"  x="228.8" y="1.6" fill="#8a9999" width="43.9" height="43.9"/>
		<g id="transitionsIcon">
			<polygon fill="#57FF86" points="258,35.7 244.8,35.7 251.4,40 "/>
            <polygon opacity="0.66" fill="#57FF86" points="254.7,34.9 258,32.7 244.8,32.7 248.1,34.9 "/>
            <polygon opacity="0.33" fill="#57FF86" points="254.7,32 258,29.8 244.8,29.8 248.1,32 "/>
            <polygon opacity="0.15" fill="#57FF86" points="254.7,29 258,26.9 244.8,26.9 248.1,29 "/>
            <polygon fill="#FF5757" points="244.8,12.3 258,12.3 251.4,8 "/>
            <polygon opacity="0.66" fill="#FF5757" points="248.1,13.1 244.8,15.3 258,15.3 254.7,13.1 "/>
            <polygon opacity="0.33" fill="#FF5757" points="248.1,16 244.8,18.2 258,18.2 254.7,16 "/>
            <polygon opacity="0.15" fill="#FF5757" points="248.1,19 244.8,21.1 258,21.1 254.7,19 "/>
            <polygon fill="#ffffff" opacity="0.25" points="255.6,8 257.8,9.4 266.4,9.4 266.4,23.3 236.4,23.3 236.4,9.4 245.1,9.4 247.2,8 235,8 235,8
			235,9.4 235,23.3 235,24.8 235,24.8 267.9,24.8 267.9,24.8 267.9,23.3 267.9,9.4 267.9,8 267.9,8 "/>
		</g>
		<g class="gloss">
			<rect x="228.8" y="1.6" opacity="0.2" fill="#262626" width="43.9" height="43.9"/>
			<rect x="228.8" y="1.6" opacity="5.000000e-02" fill="#FFFFFF" width="43.9" height="21.9"/>
		</g>
		<rect class="mouseover" visibility="hidden" x="228.8" y="1.6" opacity="5.000000e-02" fill="#FFFFFF" width="43.9" height="43.9"/>
	</g>
        <g id="timeSelectionsButton" class="button" onClick="openTimeSelModal()">
        <rect class="iconBg" x="274.2" y="1.6" fill="#262626" width="43.9" height="43.9"/>
        <rect class="active" visibility="hidden" x="274.2" y="1.6" fill="#8a9999" width="43.9" height="43.9"/>
        <!-- two vertical marker lines with a selection box between -->
        <line x1="284" y1="10" x2="284" y2="37" stroke="#57FF86" stroke-width="2"/>
        <line x1="308" y1="10" x2="308" y2="37" stroke="#57FF86" stroke-width="2"/>
        <rect x="284" y="17" width="24" height="13" fill="#57FF86" opacity="0.2"/>
        <line x1="284" y1="23" x2="308" y2="23" stroke="#57FF86" stroke-width="1" stroke-dasharray="3,2"/>
        <rect class="mouseover" visibility="hidden" x="274.2" y="1.6" opacity="0.05" fill="#FFFFFF" width="43.9" height="43.9"/>
    </g>
</svg>
    </div>
<div style = "width: 100%; background-color: #1a1a1a;">
   <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"
	 width="100%" height="100%" viewBox="0 0 320 47.2" xml:space="preserve">
    <text id="status" onClick="prompt_seek()"; text-anchor="middle"; transform="matrix(1 0 0 1 155.1 27.4)" font-family="'Open Sans'" font-size="26px"></text>
    <text id="timeUnits" text-anchor="middle"; transform="matrix(1 0 0 1 155.1 39.4)" fill="#545454" font-family="'Open Sans'" font-size="9px">Hours:Minutes:Seconds:Frames</text>
    <text id="tsNum" text-anchor="end" transform="matrix(1 0 0 1 26.3 23.3)" fill="#A8A8A8" font-family="'Open Sans'" font-size="12px">8</text>
    <text id="tsDen" transform="matrix(1 0 0 1 31.5625 33.1)" fill="#A8A8A8" font-family="'Open Sans'" font-size="12px">999</text>
    <rect id="timeSigTapTarget" x="0" y="0" width="45" height="47" fill="transparent" pointer-events="all" style="cursor:pointer" onClick="openTempoModal()"/>
    <line fill="none" stroke="#545454" stroke-miterlimit="10" x1="23.1" y1="29.5" x2="35" y2="17.6"/>
    <g id="options" class="button">
        <rect x="272.8" fill="#1A1A1A" width="47.2" height="47.2"/>
        <path fill="#404040" d="M302.3,18.7h-20.1v-2.2h20.1V18.7z M302.3,22h-20.1v2.2h20.1V22z M302.3,27.6h-20.1v2.2h20.1V27.6z"/>
        <path class="mouseover" visibility="hidden" opacity="0.1" fill="#FFFFFF" d="M302.3,18.7h-20.1v-2.2h20.1V18.7z M302.3,22h-20.1v2.2h20.1V22z M302.3,27.6h-20.1v2.2h20.1V27.6z"/>
    </g>
    </svg>
    </div>
<div id="jogger" style = "width:100%" "height:100%">

<svg version="1.1" id="joggerSvg" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"
	 width="100%" height="100%" viewBox="0 0 320 75" xml:space="preserve">
<rect id="bg" fill="#1A1A1A" width="320" height="74"/>
<rect id="hilight_below" y="74" fill="#404040" width="320" height="1"/>
<g id="wheel">
	<clipPath id="clip_rect">
		<rect id="clip_rect" width="320" height="74"/>
	</clipPath>
	<g clip-path="url(#clip_rect)">
		<path fill="#262626" d="M159,358.3c-97.7,0-177.3-79.5-177.3-177.3S61.3,3.7,159,3.7S336.3,83.3,336.3,181S256.7,358.3,159,358.3z
			"/>
		<path fill="none" stroke="#404040" stroke-width="1.1149" stroke-miterlimit="10" d="M159,358.3c-97.7,0-177.3-79.5-177.3-177.3
			S61.3,3.7,159,3.7S336.3,83.3,336.3,181S256.7,358.3,159,358.3z"/>
	</g>
	<g id="thumb" clip-path="url(#clip_rect)">
		<path fill="#383838" d="M159,58c-9.9,0-18-8.1-18-18s8.1-18,18-18s18,8.1,18,18S168.9,58,159,58z"/>
		<circle fill="none" stroke="#666666" stroke-width="2" stroke-miterlimit="10" cx="159" cy="40" r="22"/>
	</g>
	<path id="point_left" opacity="0.33" clip-path="url(#clip_rect)" fill="#808080" d="M106.5,45.2c1-1.4,1.9-2.9,3-4.3l4.1,11.5
		c-1.6-0.6-3.2-1-4.8-1.5c-1.6-0.5-3.3-0.9-5-1.3C104.7,48.1,105.6,46.7,106.5,45.2z M95.7,53.3c3.4,0.6,6.7,1.3,9.9,2.2l-4.8-11.2
		C99,47.2,97.3,50.3,95.7,53.3z M82.2,60.3c-1.8,1.1-3.5,2.4-5.3,3.5l0.6,0.9c1.8-1.2,3.5-2.4,5.3-3.5L82.2,60.3z M92.7,54.2
		c-1.9,1-3.7,2-5.6,3.1l0.6,1c1.8-1,3.6-2.1,5.5-3.1L92.7,54.2z M121.2,43c-2,0.6-4.1,1.2-6.1,1.8l0.3,1.1c2-0.6,4-1.2,6.1-1.8
		L121.2,43z M133,40.3c-2.1,0.3-4.2,0.8-6.2,1.3l0.2,1.1c2.1-0.4,4.1-0.9,6.2-1.3L133,40.3z"/>
	<path id="point_right" opacity="0.33" clip-path="url(#clip_rect)" fill="#808080" d="M214.2,49.6c-1.7,0.4-3.3,0.8-5,1.3
		c-1.6,0.5-3.2,0.9-4.8,1.5l4.1-11.5c1,1.4,2,2.9,3,4.3C212.4,46.7,213.3,48.1,214.2,49.6z M217.1,44.2l-4.8,11.2
		c3.2-0.9,6.5-1.5,9.9-2.2C220.7,50.3,219,47.2,217.1,44.2z M235.2,61.2c1.8,1.1,3.5,2.3,5.3,3.5l0.6-0.9c-1.8-1.2-3.5-2.4-5.3-3.5
		L235.2,61.2z M224.8,55.2c1.9,0.9,3.7,2,5.5,3.1l0.6-1c-1.8-1.1-3.7-2.1-5.6-3.1L224.8,55.2z M196.5,44.1c2,0.5,4,1.2,6.1,1.8
		l0.3-1.1c-2-0.6-4.1-1.3-6.1-1.8L196.5,44.1z M184.8,41.4c2.1,0.3,4.1,0.8,6.2,1.3l0.2-1.1c-2.1-0.4-4.1-0.9-6.2-1.3L184.8,41.4z"
		/>
</g>
<linearGradient id="shadow_1_" gradientUnits="userSpaceOnUse" x1="160" y1="74" x2="160" y2="56">
	<stop  offset="0" style="stop-color:#000000"/>
	<stop  offset="1.756757e-02" style="stop-color:#000000;stop-opacity:0.9824"/>
	<stop  offset="1" style="stop-color:#000000;stop-opacity:0"/>
</linearGradient>
<rect id="shadow" y="56" opacity="0.33" fill="url(#shadow_1_)" width="320" height="18"/>
</svg>
</div>

<div id="transport" style="display: flex; flex-direction: column;">


<div>
    <svg id="nextPrev" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="100%"
         height="100%" viewBox="0 0 318.9 87.8" xml:space="preserve">
    <polygon id="markerSecBg" fill="#262626" points="164.3,12.5 159,17.8 153.8,12.5 70.4,12.5 70.4,79.2 153.8,79.2 159,74
        164.3,79.2 248.3,79.2 248.3,12.5 "/>
    <rect id="markerStrip" x="70.4" y="50.4" fill="#2D2D2D" width="177.9" height="15"/>
    <rect id="regionStrip" x="70.4" y="20.2" fill="#2D2D2D" width="177.9" height="15"/>
    <rect id="timeSelBar" x="0" y="50.4" width="0" height="15" fill="#57FF86" opacity="0.15" visibility="hidden"/>
    <path id="locTriangles" fill="#666666" d="M152.4,87.8l6.6-6.6l6.6,6.6H152.4z M152.4,4l6.6,6.6l6.6-6.6H152.4z"/>
    <style type="text/css">
        .st0{fill:none;stroke:#808080;stroke-miterlimit:10;}
        .st3{font-family:'Open Sans';text-anchor:middle;}
        .st4{font-size:10px;}
    </style>
    <g id="region1" visibility="hidden">
        <line id="r1StalkL" class="st0" x1="45.6" y1="30.7" x2="45.6" y2="73.6"/>
        <line id="r1StalkR" class="st0" x1="102.5" y1="30.7" x2="102.5" y2="73.6"/>
        <rect id="r1Rect" x="45.6" y="20.2" rx="3" ry="3" stroke="#808080" width="56.9" height="15.1"/>
        <text id="r1Name" transform="matrix(1 0 0 1 74.5 31)" class="st3 st4"></text>
    </g>
    <g id="region2" visibility="hidden">
        <line id="r2StalkL" class="st0" x1="45.6" y1="30.7" x2="45.6" y2="73.6"/>
        <line id="r2StalkR" class="st0" x1="102.5" y1="30.7" x2="102.5" y2="73.6"/>
        <rect id="r2Rect" x="45.6" y="20.2" rx="3" ry="3" stroke="#808080" width="56.9" height="15.1"/>
        <text id="r2Name" transform="matrix(1 0 0 1 74.5 31)" class="st3 st4"></text>
    </g>
    <g id="region3" visibility="hidden">
        <line id="r3StalkL" class="st0" x1="45.6" y1="30.7" x2="45.6" y2="73.6"/>
        <line id="r3StalkR" class="st0" x1="102.5" y1="30.7" x2="102.5" y2="73.6"/>
        <rect id="r3Rect" x="45.6" y="20.2" rx="3" ry="3" stroke="#808080" width="56.9" height="15.1"/>
        <text id="r3Name" transform="matrix(1 0 0 1 74.5 31)" class="st3 st4"></text>
    </g>
    <g id="region4" visibility="hidden">
        <line id="r4StalkL" class="st0" x1="45.6" y1="30.7" x2="45.6" y2="73.6"/>
        <line id="r4StalkR" class="st0" x1="102.5" y1="30.7" x2="102.5" y2="73.6"/>
        <rect id="r4Rect" x="45.6" y="20.2" rx="3" ry="3" stroke="#808080" width="56.9" height="15.1"/>
        <text id="r4Name" transform="matrix(1 0 0 1 74.5 31)" class="st3 st4"></text>
    </g>


    <g id="marker1" visibility="hidden">
        <line id="markerStalk" fill="none" stroke="#808080" stroke-miterlimit="10" x1="102.5" y1="59.7" x2="102.5" y2="73.6"/>
        <rect id="marker1Bg" x="95" y="50.4" rx="3" ry="3" stroke="#808080" stroke-miterlimit="10" width="15" height="15"/>
        <text id="marker1Number" transform="matrix(1 0 0 1 102.5 61.5)" fill="#A8A8A8" font-family="'Open Sans'" text-anchor="middle" font-size="10px"></text>
        <g><defs>
                <rect id="npClip1" x="74.1" y="35.8" width="56.8" height="14.6"/>
            </defs>
            <clipPath id="npClip2">
                <use xlink:href="#npClip1"  overflow="visible"/>
            </clipPath>
            <g clip-path="url(#npClip2)">
                <text id="prevMarkerName" transform="matrix(1 0 0 1 102.5 46.6)" fill="#A8A8A8" font-family="'Open Sans'" text-anchor="middle" font-size="10px"></text>
            </g>
        </g>
    </g>
    <g id="marker2" visibility="hidden">
        <line id="markerStalk_1_" fill="none" stroke="#808080" stroke-miterlimit="10" x1="159.3" y1="59.7" x2="159.3" y2="73.6"/>
       <rect id="marker2Bg" x="151.8" y="50.4" rx="3" ry="3" stroke="#808080" stroke-miterlimit="10" width="15" height="15"/>
            <text id="marker2Number" transform="matrix(1 0 0 1 159.5 61.5)" fill="#A8A8A8" font-family="'Open Sans'" text-anchor="middle" font-size="10px"></text>
        <g><defs>
                <rect id="npClip3" x="130.9" y="35.8" width="56.8" height="14.6"/>
            </defs>
            <clipPath id="npClip4">
                <use xlink:href="#npClip3"  overflow="visible"/>
            </clipPath>
            <g clip-path="url(#npClip4)">
                <text id="atMarkerName" transform="matrix(1 0 0 1 159.5 46.6)" fill="#A8A8A8" font-family="'Open Sans'" text-anchor="middle" font-size="10px"></text>
            </g>
        </g>
    </g>
    <g id="marker3" visibility="hidden">
        <line id="markerStalk_2_" fill="none" stroke="#808080" stroke-miterlimit="10" x1="216.1" y1="59.7" x2="216.1" y2="73.6"/>
        <rect id="marker3Bg" x="208.6" y="50.4" rx="3" ry="3" stroke="#808080" stroke-miterlimit="10" width="15" height="15"/>
            <text id="marker3Number" transform="matrix(1 0 0 1 216 61.5)" fill="#A8A8A8" font-family="'Open Sans'" text-anchor="middle" font-size="10px"></text>
        <g><defs>
                <rect id="npClip5" x="187.7" y="35.8" width="56.8" height="14.6"/>
            </defs>
            <clipPath id="npClip6">
                <use xlink:href="#npClip5"  overflow="visible"/>
            </clipPath>
            <g clip-path="url(#npClip6)">
                <text id="nextMarkerName" transform="matrix(1 0 0 1 216 46.6)" fill="#A8A8A8" font-family="'Open Sans'" text-anchor="middle" font-size="10px"></text>
            </g>
        </g>
    </g>
    <g id=nextButton class="button" onClick="wwr_req(40173)">
        <path class="shadow" opacity="0.15" d="M248.3,83.5h29.6c17.8,0,32.3-14.4,32.3-32.3v-5.6h-64.6v35
            C245.6,82.4,246.8,83.5,248.3,83.5z"/>
        <path fill="#1A1A1A" d="M248.3,12.5H278c18.4,0,33.4,15,33.4,33.4s-15,33.4-33.4,33.4h-29.7c-2,0-3.7-1.6-3.7-3.7V16.2
            C244.6,14.1,246.3,12.5,248.3,12.5L248.3,12.5z"/>

            <linearGradient id="mrg1" gradientUnits="userSpaceOnUse" x1="-1856.4718" y1="405.6207" x2="-1856.4718" y2="469.644" gradientTransform="matrix(-1 0 0 -1 -1578.4503 483.5079)">
            <stop  offset="0" style="stop-color:#262626"/>
            <stop  offset="1" style="stop-color:#404040"/>
        </linearGradient>
        <path fill="url(#mrg1)" d="M278,77.9c17.7,0,32-14.3,32-32s-14.3-32-32-32h-29.7c-1.2,0-2.3,1.1-2.3,2.3v59.4
            c0,1.4,1.1,2.3,2.3,2.3H278z"/>
        <path opacity="5.000000e-02" d="M310.2,45.7H246v29.4c0,1.5,1.2,2.7,2.7,2.7h29.4
            C295.9,77.9,310.2,63.4,310.2,45.7L310.2,45.7z"/>
        <path id="iconEnd" visibility="hidden" fill="#808080" d="M279.4,46l-17.4-11.3v22.6L279.4,46z M281.4,34.7h5v22.6h-5V34.7z"/>
        <path id="iconNext" fill="#808080" d="M279.4,46l-17.4-11.3v22.6L279.4,46z M278.7,34.7h10.4l-5.2,5L278.7,34.7z
             M281.4,42.2h5v15h-5V42.2z"/>
        <path class="mouseover" visibility="hidden" opacity="0.05" fill="#FFFFFF" d="M278,77.9c17.7,0,32-14.3,32-32s-14.3-32-32-32h-29.7
            c-1.2,0-2.3,1.1-2.3,2.3v59.4c0,1.4,1.1,2.3,2.3,2.3H278z"/>
    </g>
    <g id=prevButton class="button" onClick="wwr_req(40172)">
        <path class="shadow" opacity="0.15" d="M70.4,83.5H40.8C23,83.5,8.5,69,8.5,51.2v-5.6h64.6v35
            C73.1,82.4,71.9,83.5,70.4,83.5z"/>
        <path fill="#1A1A1A" d="M70.4,12.5H40.7c-18.4,0-33.4,15-33.4,33.4s15,33.4,33.4,33.4h29.7c2,0,3.7-1.6,3.7-3.7V16.2
            C74.1,14.1,72.4,12.5,70.4,12.5L70.4,12.5z"/>

            <linearGradient id="mrg2" gradientUnits="userSpaceOnUse" x1="-436.7075" y1="405.6207" x2="-436.7075" y2="469.644" gradientTransform="matrix(1 0 0 -1 477.3987 483.5079)">
            <stop  offset="0" style="stop-color:#262626"/>
            <stop  offset="1" style="stop-color:#404040"/>
        </linearGradient>
        <path fill="url(#mrg2)" d="M40.7,77.9c-17.7,0-32-14.3-32-32s14.3-32,32-32h29.7c1.2,0,2.3,1.1,2.3,2.3v59.4
            c0,1.4-1.1,2.3-2.3,2.3H40.7z"/>
        <path opacity="5.000000e-02" d="M8.5,45.7h64.2v29.4c0,1.5-1.2,2.7-2.7,2.7H40.6
            C22.8,77.9,8.5,63.4,8.5,45.7L8.5,45.7z"/>
        <path id="iconHome" visibility="hidden" fill="#808080" d="M39.3,46l17.4-11.3v22.6L39.3,46z M37.3,34.7h-5v22.6h5V34.7z"/>
        <path id="iconPrev" fill="#808080" d="M39.3,46l17.4-11.3v22.6L39.3,46z M40,34.7H29.7l5.2,5L40,34.7z M37.3,42.2h-5v15
            h5V42.2z"/>
        <path class="mouseover" visibility="hidden" opacity="0.05" fill="#FFFFFF" d="M40.7,77.9c-17.7,0-32-14.3-32-32s14.3-32,32-32h29.7
            c1.2,0,2.3,1.1,2.3,2.3v59.4c0,1.4-1.1,2.3-2.3,2.3H40.7z"/>
    </g>
    <g id="dropMarker" class="button" visibility="hidden" onClick="wwr_req('40157;40898')">
        <rect x="145.2" y="40.7" fill-opacity="0.25" stroke="#808080" stroke-dasharray="2, 4" stroke-miterlimit="10" rx="3" ry="3" width="28.4" height="28.4"/>
        <path id="+" fill="none" stroke="#808080" stroke-width="3" stroke-miterlimit="10" d="M159.4,63.3V46.5 M151.1,54.9h16.7"/>
        <rect id="dropMarkerHitbox" x="131.2" y="35.2" fill="none" width="56.6" height="44"/>
        <rect class="mouseover" visibility="hidden" x="145.2" y="40.7" opacity="0.15" fill="#FFFFFF" width="28.4" height="28.4"/>
    </g>
    </svg>

</div>

<div id="transport_r2">
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="100%"
 height="100%" viewBox="0 0 303.6 107.6" xml:space="preserve">
    <circle id="playLineBg" fill="#222625" cx="151.8" cy="52.4" r="52.3"/>
    <circle id="playLine" fill="none" stroke-dasharray="50" stroke-dashoffset="10" stroke="#00FE95" stroke-width="6" stroke-miterlimit="10" cx="151.8" cy="52.4" r="48"/>

    <g id="play" class="button" onClick="wwr_req(1007)">
        <g id=playButtonOn visibility="hidden">
            <path fill="#00FF99" d="M151.8,97c-24.6,0-44.6-20-44.6-44.6s20-44.6,44.6-44.6s44.6,20,44.6,44.6S176.4,97,151.8,97z"/>
            <path fill="#1A1A1A" d="M151.8,8.4c24.3,0,44,19.7,44,44s-19.7,44-44,44s-44-19.7-44-44S127.5,8.4,151.8,8.4 M151.8,7.2
                c-25,0-45.2,20.2-45.2,45.2s20.2,45.2,45.2,45.2S197,77.4,197,52.4S176.8,7.2,151.8,7.2L151.8,7.2z"/>

                <linearGradient id="pograd" gradientUnits="userSpaceOnUse" x1="151.7784" y1="-1823.5439" x2="151.7784" y2="-1779.5526" gradientTransform="matrix(1 0 0 -1 0 -1771.1405)">
                <stop  offset="0" style="stop-color:#FFFFFF;stop-opacity:0.25"/>
                <stop  offset="1" style="stop-color:#FFFFFF"/>
            </linearGradient>
            <path opacity="0.15" fill="url(#pograd)" d="M195.8,52.4h-88l0,0c0-24.3,19.7-44,44-44l0,0
                C176.2,8.4,195.8,28.1,195.8,52.4L195.8,52.4z"/>
            <polygon fill="#FFFFFF" points="139.6,67.9 139.6,37.1 170.4,52.4 		"/>
            <path class="mouseover" visibility="hidden" opacity="0.2" fill="#FFFFFF" d="M151.8,97c-24.6,0-44.6-20-44.6-44.6
                s20-44.6,44.6-44.6s44.6,20,44.6,44.6S176.4,97,151.8,97z"/>
        </g>
        <g id=playButtonOff visibility="visible">
            <circle  class="shadow" opacity="0.15" cx="151.8" cy="62.4" r="45.2"/>

                <linearGradient id="pffgrad" gradientUnits="userSpaceOnUse" x1="151.7784" y1="1033.0232" x2="151.7784" y2="943.7836" gradientTransform="matrix(1 0 0 1 0 -936)">
                <stop  offset="0" style="stop-color:#697373"/>
                <stop  offset="1" style="stop-color:#B0BBBB"/>
            </linearGradient>
            <path fill="url(#pffgrad)" d="M151.8,97c-24.6,0-44.6-20-44.6-44.6s20-44.6,44.6-44.6s44.6,20,44.6,44.6S176.4,97,151.8,97z"/>
            <path fill="#1A1A1A" d="M151.8,8.4c24.3,0,44,19.7,44,44s-19.7,44-44,44s-44-19.7-44-44S127.5,8.4,151.8,8.4 M151.8,7.2
                c-25,0-45.2,20.2-45.2,45.2s20.2,45.2,45.2,45.2S197,77.4,197,52.4S176.8,7.2,151.8,7.2L151.8,7.2z"/>

                <linearGradient id="pffgrad2" gradientUnits="userSpaceOnUse" x1="151.7784" y1="-1823.5439" x2="151.7784" y2="-1779.5526" gradientTransform="matrix(1 0 0 -1 0 -1771.1405)">
                <stop  offset="0" style="stop-color:#FFFFFF;stop-opacity:0.25"/>
                <stop  offset="1" style="stop-color:#FFFFFF"/>
            </linearGradient>
            <path opacity="0.15" fill="url(#pffgrad2)" d="M195.8,52.4h-88l0,0c0-24.3,19.7-44,44-44l0,0
                C176.2,8.4,195.8,28.1,195.8,52.4L195.8,52.4z"/>
            <polygon fill="#1A1A1A" points="139.6,67.9 139.6,37.1 170.4,52.4 "/>
            <path class="mouseover" visibility="hidden" opacity="0.2" fill="#FFFFFF" d="M151.8,97c-24.6,0-44.6-20-44.6-44.6
                s20-44.6,44.6-44.6s44.6,20,44.6,44.6S176.4,97,151.8,97z"/>
        </g>
    </g>
    <g id="stopButton" class="button" onClick="wwr_req(40667)">
        <path  class="shadow" opacity="0.15" d="M8.4,58.7c0,0.6,0,1.1,0,1.7v0c0,25.9,21,47,47,47h37
            c5.6,0,11-2.1,15.1-5.9c-10-10.8-16.1-25.2-16.1-41.1c0-0.6,0-1.1,0-1.7H8.4z"/>
        <g>
            <linearGradient id="stgrad" gradientUnits="userSpaceOnUse" x1="58.0022" y1="4.8047" x2="58.0022" y2="100.002">
                <stop  offset="0" style="stop-color:#404040"/>
                <stop  offset="1" style="stop-color:#262626"/>
            </linearGradient>
            <path fill="url(#stgrad)" d="M55.3,100C29.1,100,7.7,78.6,7.7,52.4S29.1,4.8,55.3,4.8h36.9c5.8,0,11.4,2.2,15.6,6.1l0.5,0.4
                l-0.4,0.5C97.6,22.9,91.9,37.3,91.9,52.4c0,15.1,5.7,29.6,16,40.7l0.4,0.5l-0.5,0.4c-4.3,3.9-9.8,6-15.6,6H55.3z"/>
            <path fill="#1A1A1A" d="M92.2,5.4c5.6,0,11.1,2.1,15.2,5.9c-10,10.8-16.1,25.2-16.1,41.1c0,15.9,6.1,30.3,16.1,41.1
                c-4.1,3.8-9.5,5.9-15.1,5.9h-37c-25.9,0-47-21-47-47v0c0-25.9,21-47,47-47H92.2 M92.2,4.2H55.3C28.7,4.2,7.1,25.8,7.1,52.4
                c0,26.6,21.6,48.2,48.2,48.2h37c5.9,0,11.6-2.2,16-6.2l0.9-0.8l-0.9-0.9c-10.2-11-15.8-25.3-15.8-40.2c0-14.9,5.6-29.2,15.8-40.2
                l0.9-0.9l-0.9-0.8C103.8,6.4,98.1,4.2,92.2,4.2L92.2,4.2z"/>
        </g>
        <rect x="39.9" y="34.3" fill="#808080" width="32.9" height="32.9"/>
        <linearGradient id="stgrad2" gradientUnits="userSpaceOnUse" x1="57.8796" y1="50.7389" x2="57.8796" y2="5.4297">
            <stop  offset="0" style="stop-color:#FFFFFF;stop-opacity:0.25"/>
            <stop  offset="1" style="stop-color:#FFFFFF"/>
        </linearGradient>
        <path opacity="5.000000e-02" fill="url(#stgrad2)" d="M55.3,5.4C29.9,5.4,9.3,25.6,8.4,50.7h82.9c0.4-15.2,6.4-29,16.1-39.4l0,0
            c-4.1-3.8-9.5-5.9-15.1-5.9H55.3z"/>
        <path opacity="5.000000e-02" d="M8.4,50.7c0,0.6,0,1.1,0,1.7v0c0,25.9,21,47,47,47h37c5.6,0,11-2.1,15.1-5.9
            c-10-10.8-16.1-25.2-16.1-41.1c0-0.6,0-1.1,0-1.7H8.4z"/>
        <path class="mouseover" visibility="hidden" opacity="0.05" fill="#FFFFFF" d="M107.4,93.5c-10-10.8-16.1-25.2-16.1-41.1
            c0-15.9,6.1-30.3,16.1-41.1c-4.2-3.8-9.6-5.9-15.2-5.9H55.3c-25.9,0-47,21-47,47v0c0,25.9,21,47,47,47h37
            C97.9,99.4,103.3,97.3,107.4,93.5z"/>
    </g>
    <g id="pause" class="button" onClick="wwr_req(1008)">
        <g id="pauseButtonOn" visibility="hidden">
            <path class="shadow" opacity="0.15" d="M295.2,58.7c0,0.6,0,1.1,0,1.7v0c0,25.9-21,47-47,47h-37
                c-5.6,0-11-2.1-15.1-5.9c10-10.8,16.1-25.2,16.1-41.1c0-0.6,0-1.1,0-1.7H295.2z"/>
            <path fill="#7DBBBB" stroke="#000000" stroke-width="1.25" stroke-miterlimit="10" d="M196.2,93.5c10-10.8,16.1-25.2,16.1-41.1
                c0-15.9-6.1-30.3-16.1-41.1c4.2-3.8,9.6-5.9,15.2-5.9h36.9c25.9,0,47,21,47,47v0c0,25.9-21,47-47,47h-37
                C205.7,99.4,200.3,97.3,196.2,93.5z"/>
            <path fill="#FFFFFF" d="M230.8,67.2h11V34.3h-11V67.2z M252.6,34.3v32.9h11V34.3H252.6z"/>
            <path class="mouseover" visibility="hidden" opacity="0.2" fill="#FFFFFF" d="M196.2,93.5c10-10.8,16.1-25.2,16.1-41.1
                c0-15.9-6.1-30.3-16.1-41.1c4.2-3.8,9.6-5.9,15.2-5.9h36.9c25.9,0,47,21,47,47v0c0,25.9-21,47-47,47h-37
                C205.7,99.4,200.3,97.3,196.2,93.5z"/>
        </g>
        <g id="pauseButtonOff" visibility="visible">
            <path class="shadow" opacity="0.15" d="M295.2,58.7c0,0.6,0,1.1,0,1.7v0c0,25.9-21,47-47,47h-37
                c-5.6,0-11-2.1-15.1-5.9c10-10.8,16.1-25.2,16.1-41.1c0-0.6,0-1.1,0-1.7H295.2z"/>
            <g>
                    <linearGradient id="pfgrad" gradientUnits="userSpaceOnUse" x1="269.153" y1="4.8047" x2="269.153" y2="100.002" gradientTransform="matrix(-1 0 0 1 514.7297 0)">
                    <stop  offset="0" style="stop-color:#404040"/>
                    <stop  offset="1" style="stop-color:#262626"/>
                </linearGradient>
                <path fill="url(#pfgrad)" d="M211.3,100c-5.8,0-11.3-2.1-15.6-6l-0.5-0.4l0.4-0.5c10.3-11.1,16-25.6,16-40.7
                    c0-15.1-5.7-29.5-15.9-40.6l-0.4-0.5l0.5-0.4c4.3-3.9,9.8-6.1,15.6-6.1h36.9c26.2,0,47.6,21.4,47.6,47.6S274.5,100,248.3,100
                    H211.3z"/>
                <path fill="#1A1A1A" d="M248.3,5.4c25.9,0,47,21,47,47v0c0,25.9-21,47-47,47h-37c-5.6,0-11-2.1-15.1-5.9
                    c10-10.8,16.1-25.2,16.1-41.1c0-15.9-6.1-30.3-16.1-41.1c4.2-3.8,9.6-5.9,15.2-5.9H248.3 M248.3,4.2h-36.9
                    c-6,0-11.7,2.2-16.1,6.2l-0.9,0.8l0.9,0.9c10.2,11,15.8,25.3,15.8,40.2c0,15-5.6,29.2-15.8,40.2l-0.9,0.9l0.9,0.8
                    c4.4,4,10.1,6.2,16,6.2h37c26.6,0,48.2-21.6,48.2-48.2C296.5,25.8,274.9,4.2,248.3,4.2L248.3,4.2z"/>
            </g>
            <path fill="#808080" d="M230.8,67.2h11V34.3h-11V67.2z M252.6,34.3v32.9h11V34.3H252.6z"/>
                <linearGradient id="pfgrad2" gradientUnits="userSpaceOnUse" x1="269.0302" y1="50.7389" x2="269.0302" y2="5.4297" gradientTransform="matrix(-1 0 0 1 514.7297 0)">
                <stop  offset="0" style="stop-color:#FFFFFF;stop-opacity:0.25"/>
                <stop  offset="1" style="stop-color:#FFFFFF"/>
            </linearGradient>
            <path opacity="5.000000e-02" fill="url(#pfgrad2)" d="M248.3,5.4c25.4,0,46.1,20.1,46.9,45.3h-82.9c-0.4-15.2-6.4-29-16.1-39.4
                l0,0c4.1-3.8,9.5-5.9,15.1-5.9H248.3z"/>
            <path opacity="5.000000e-02" d="M295.2,50.7c0,0.6,0,1.1,0,1.7v0c0,25.9-21,47-47,47h-37c-5.6,0-11-2.1-15.1-5.9
                c10-10.8,16.1-25.2,16.1-41.1c0-0.6,0-1.1,0-1.7H295.2z"/>
            <path class="mouseover" visibility="hidden" opacity="0.05" fill="#FFFFFF" d="M196.2,93.5c10-10.8,16.1-25.2,16.1-41.1
                c0-15.9-6.1-30.3-16.1-41.1c4.2-3.8,9.6-5.9,15.2-5.9h36.9c25.9,0,47,21,47,47v0c0,25.9-21,47-47,47h-37
                C205.7,99.4,200.3,97.3,196.2,93.5z"/>
        </g>
    </g>
</svg>
    </div>

    <div id="transport_r3" style="display:flex; margin: 1.5%;">

    <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="33%" height="100%" viewBox="0 0 101.5 108" xml:space="preserve"><g onClick="wwr_req(1068)">	 <g id="repeat_on" class="button"  visibility="hidden">	<g>	<path fill="#7DBBBB" d="M47.9,96.7c-26,0-47.2-21.2-47.2-47.2S21.9,2.3,47.9,2.3s47.2,21.2,47.2,47.2S73.9,96.7,47.9,96.7z"/>	<path fill="#1A1A1A" d="M47.9,3c25.7,0,46.5,20.8,46.5,46.5v0C94.4,75.2,73.6,96,47.9,96h0C22.2,96,1.4,75.2,1.4,49.5v0 C1.4,23.8,22.2,3,47.9,3L47.9,3 M47.9,1.7C21.5,1.7,0.1,23.1,0.1,49.5c0,26.4,21.5,47.8,47.8,47.8s47.8-21.5,47.8-47.8	C95.7,23.1,74.3,1.7,47.9,1.7L47.9,1.7z"/></g><path fill="#FFFFFF" d="M63.4,66.8l2,5.1l-17.5-2.5l10.9-13.9l1.8,4.5c2.4-2.9,3.8-6.6,3.8-10.5c0-7.7-5.5-14.5-13-16.2 c-1.8-0.4-3-2.2-2.6-4c0.4-1.8,2.2-3,4-2.6c10.6,2.3,18.3,11.9,18.3,22.7C71.2,56.2,68.3,62.4,63.4,66.8z M37,43.5l10.9-13.9 l-17.5-2.5l2,5.1c-4.9,4.4-7.8,10.6-7.8,17.3c0,10.9,7.4,20.2,18,22.7c0.3,0.1,0.5,0.1,0.8,0.1c1.5,0,2.9-1.1,3.3-2.6 c0.4-1.8-0.7-3.6-2.5-4c-7.5-1.7-12.8-8.4-12.8-16.1c0-3.9,1.3-7.6,3.8-10.5L37,43.5z"/>	<path class="mouseover" visibility="hidden" opacity="0.15" fill="#FFFFFF" d="M47.9,96L47.9,96C22.2,96,1.4,75.2,1.4,49.5v0C1.4,23.8,22.2,3,47.9,3h0 c25.7,0,46.5,20.8,46.5,46.5v0C94.4,75.2,73.6,96,47.9,96z"/></g><g id="repeat_off" class="button"> <path class="shadow" display="inline" opacity="0.2" d="M47.9,104L47.9,104C22.2,104,1.4,83.2,1.4,57.5 v-8h93v8C94.4,83.2,73.6,104,47.9,104z"/>	<g display="inline"> <linearGradient id="rptGrad" gradientUnits="userSpaceOnUse" x1="-45.1001" y1="89.3403" x2="-45.1001" y2="183.6602" gradientTransform="matrix(1 0 0 1 93 -87)">	<stop  offset="0" style="stop-color:#404040"/>	<stop  offset="1" style="stop-color:#262626"/>	</linearGradient> <path fill="url(#rptGrad)" d="M47.9,96.7c-26,0-47.2-21.2-47.2-47.2S21.9,2.3,47.9,2.3s47.2,21.2,47.2,47.2S73.9,96.7,47.9,96.7z	"/>	<path fill="#1A1A1A" d="M47.9,3c25.7,0,46.5,20.8,46.5,46.5v0C94.4,75.2,73.6,96,47.9,96h0C22.2,96,1.4,75.2,1.4,49.5v0 C1.4,23.8,22.2,3,47.9,3L47.9,3 M47.9,1.7C21.5,1.7,0.1,23.1,0.1,49.5c0,26.4,21.5,47.8,47.8,47.8s47.8-21.5,47.8-47.8	C95.7,23.1,74.3,1.7,47.9,1.7L47.9,1.7z"/></g><path fill="#808080" d="M63.4,66.8l2,5.1l-17.5-2.5l10.9-13.9l1.8,4.5c2.4-2.9,3.8-6.6,3.8-10.5	c0-7.7-5.5-14.5-13-16.2c-1.8-0.4-3-2.2-2.6-4c0.4-1.8,2.2-3,4-2.6c10.6,2.3,18.3,11.9,18.3,22.7C71.2,56.2,68.3,62.4,63.4,66.8z M37,43.5l10.9-13.9l-17.5-2.5l2,5.1c-4.9,4.4-7.8,10.6-7.8,17.3c0,10.9,7.4,20.2,18,22.7c0.3,0.1,0.5,0.1,0.8,0.1	c1.5,0,2.9-1.1,3.3-2.6c0.4-1.8-0.7-3.6-2.5-4c-7.5-1.7-12.8-8.4-12.8-16.1c0-3.9,1.3-7.6,3.8-10.5L37,43.5z"/>	<path class="mouseover" visibility="hidden" opacity="0.05" fill="#FFFFFF" d="M47.9,96L47.9,96C22.2,96,1.4,75.2,1.4,49.5v0 C1.4,23.8,22.2,3,47.9,3h0c25.7,0,46.5,20.8,46.5,46.5v0C94.4,75.2,73.6,96,47.9,96z"/></g></g></svg>


    <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="66%" height="100%" viewBox="0 0 201.4 108" xml:space="preserve"><path id="bg" fill="#262626" d="M151.7,99.5H48.6V0l103.1,0c27.5,0,49.7,22.3,49.7,49.7v0C201.4,77.2,179.2,99.5,151.7,99.5z"/><circle fill="#333333" cx="151.5" cy="49.4" r="26.4"/><g id="armed" class="button" ><text id="armed_count" text-anchor="middle" transform="matrix(1 0 0 1 152 67)" fill="#788282" font-family="'Open Sans'" font-weight="700" font-size="49px"></text>	<path id="armed_text" fill="#5D3729" d="M110.7,63.7l2-1.1l-1-3.7l-2.3,0l-0.9-3.3l12.3,0.6l1.1,4.1L111.7,67L110.7,63.7z M115,61.3l1.7-1c0.4-0.2,0.9-0.5,1.5-0.8c0.6-0.3,1-0.6,1.3-0.7c-0.3,0-0.7,0.1-1.4,0.1c-0.6,0-1.9,0-3.8,0.1L115,61.3z M119.4,71.7l-3.5,2.5l-1.8-2.6l9.5-6.8l2.2,3.1c1.8,2.6,1.8,4.5,0,5.9c-1.1,0.8-2.3,0.9-3.7,0.2l-2.2,5.7l-2.1-2.9l2-4.5	L119.4,71.7z M121.4,70.3l0.3,0.5c0.6,0.9,1.4,1.1,2.1,0.5c0.7-0.5,0.7-1.1,0-2l-0.4-0.5L121.4,70.3z M129.1,87l-5.6-4.1l7-9.4 l5.6,4.1l-1.5,2l-3-2.3l-1.1,1.5l2.8,2.1l-1.5,2l-2.8-2.1l-1.3,1.8l3,2.3L129.1,87z M147.5,93.2l-0.2-2.3l-3.7-0.6l-0.9,2.1 l-3.4-0.6l5.6-11l4.2,0.7l1.9,12.2L147.5,93.2z M147,88.3l-0.2-2c0-0.4-0.1-1-0.2-1.7c-0.1-0.7-0.1-1.2-0.1-1.5 c-0.1,0.3-0.3,0.7-0.5,1.3c-0.2,0.6-0.7,1.8-1.5,3.5L147,88.3z M158.4,88.6l0.8,4.2l-3.1,0.6l-2.2-11.5l3.8-0.7 c3.1-0.6,4.9,0.2,5.3,2.5c0.3,1.3-0.2,2.5-1.4,3.5l4.3,4.4l-3.5,0.7l-3.2-3.7L158.4,88.6z M157.9,86.3l0.6-0.1 c1.1-0.2,1.5-0.8,1.3-1.7c-0.2-0.8-0.8-1.1-1.8-0.9l-0.6,0.1L157.9,86.3z M175.3,86.7l-6.7-5.6l-0.1,0c0.9,1.1,1.6,2,2,2.7l2.9,4.2 l-2.3,1.6l-6.6-9.6l3.5-2.4l6.7,5.5l0.1,0l-2.7-8.2l3.5-2.4L182,82l-2.4,1.6l-2.9-4.2c-0.2-0.2-0.3-0.5-0.5-0.7 c-0.2-0.3-0.6-1-1.3-2l-0.1,0l2.8,8.3L175.3,86.7z M190.2,71.1l-3.9,5.7l-9.7-6.5l3.9-5.7l2.1,1.4l-2.1,3.1l1.5,1l2-2.9l2.1,1.4 l-2,2.9l1.8,1.2l2.1-3.1L190.2,71.1z M189.5,54.8c1.9,0.5,3.2,1.4,3.9,2.7c0.7,1.3,0.8,2.9,0.3,4.8l-1,3.6l-11.3-3.1l1.1-3.9 c0.5-1.8,1.3-3.1,2.5-3.8C186.2,54.4,187.7,54.3,189.5,54.8z M188.7,58c-1-0.3-1.9-0.3-2.5,0c-0.6,0.3-1,0.8-1.3,1.7l-0.2,0.9	l6.3,1.7l0.2-0.7c0.3-0.9,0.2-1.7-0.2-2.3C190.6,58.7,189.8,58.3,188.7,58z M128.1,27.2l-2.1,2.4l-6.9-5.9l-1.9,2.2l-2-1.7l5.8-6.7 l2,1.7l-1.8,2.2L128.1,27.2z M132.1,18.5l2.2,3.7l-2.7,1.6l-5.9-10.1l3.3-1.9c2.7-1.6,4.7-1.4,5.9,0.6c0.7,1.2,0.6,2.4-0.1,3.7 l5.5,2.7l-3.1,1.8l-4.3-2.4L132.1,18.5z M130.9,16.5l0.5-0.3c0.9-0.6,1.2-1.3,0.7-2.1c-0.4-0.7-1.1-0.8-2-0.2l-0.5,0.3L130.9,16.5z M148.6,17.2l-0.9-2.1l-3.7,0.6l-0.2,2.3l-3.4,0.6l1.8-12.2l4.2-0.7l5.8,10.9L148.6,17.2z M146.6,12.7l-0.8-1.8	c-0.2-0.4-0.4-0.9-0.7-1.6c-0.3-0.6-0.5-1.1-0.6-1.4c0,0.3,0,0.7-0.1,1.4s-0.1,1.9-0.3,3.8L146.6,12.7z M160.4,8.9 c-0.7-0.1-1.4,0.1-1.9,0.6c-0.5,0.5-0.9,1.3-1.1,2.4c-0.4,2.2,0.2,3.5,1.9,3.8c0.5,0.1,1,0.1,1.5,0.1s1-0.1,1.5-0.2l-0.5,2.6	c-1,0.2-2.2,0.2-3.4,0c-1.7-0.3-3-1.1-3.7-2.3c-0.7-1.2-0.9-2.7-0.6-4.6c0.2-1.2,0.6-2.2,1.3-3c0.6-0.8,1.4-1.4,2.3-1.7	s2-0.4,3.1-0.2c1.2,0.2,2.4,0.7,3.4,1.5l-1.4,2.3c-0.4-0.3-0.8-0.5-1.2-0.7C161.3,9.1,160.9,9,160.4,8.9z M172.8,24.6l-3.1-1.8 l0.3-5l-1.1,0l-2,3.4l-2.7-1.6l6-10l2.7,1.6l-2.6,4.4c0.3-0.2,0.8-0.5,1.6-0.8l3.9-1.8l3,1.8l-5.8,2.6L172.8,24.6z M181.5,29.4 c-0.6,0.5-1.2,0.7-1.8,0.8c-0.7,0.1-1.3,0-2-0.4c-0.7-0.3-1.3-0.8-1.9-1.6c-0.5-0.6-0.9-1.1-1.1-1.6c-0.3-0.5-0.5-1-0.6-1.6 l2.1-1.8c0.2,0.7,0.4,1.3,0.7,1.9c0.3,0.6,0.6,1.1,1,1.5c0.3,0.4,0.6,0.6,0.9,0.6s0.5,0,0.7-0.2c0.1-0.1,0.2-0.2,0.2-0.4 c0-0.1,0-0.3,0-0.6c0-0.2-0.2-0.8-0.4-1.7c-0.2-0.8-0.3-1.5-0.3-2c0-0.5,0.1-1,0.3-1.4c0.2-0.4,0.5-0.8,1-1.2 c0.8-0.7,1.7-0.9,2.7-0.7c1,0.2,1.9,0.8,2.8,1.9c0.8,0.9,1.4,2,1.8,3.4l-2.5,0.8c-0.3-1.2-0.7-2-1.3-2.6c-0.3-0.3-0.5-0.5-0.7-0.5	s-0.4,0-0.6,0.1c-0.2,0.1-0.3,0.4-0.2,0.7c0,0.3,0.2,1,0.5,2.1c0.3,1.1,0.4,1.9,0.2,2.5C182.4,28.3,182.1,28.9,181.5,29.4z"/></g><g id="abort" class="button" style="visibility:hidden" onClick="prompt_abort()"> <path id="abort_text" fill="#FF2200" d="M113.5,57.4l-4.1,0.9l-0.7-3.1l11.4-2.6l0.8,3.7c0.7,3.1-0.1,4.9-2.3,5.4 c-1.3,0.3-2.5-0.1-3.5-1.2l-4.2,4.4l-0.8-3.5l3.6-3.4L113.5,57.4z M115.9,56.9l0.1,0.6c0.2,1.1,0.8,1.5,1.8,1.3 c0.8-0.2,1.1-0.8,0.8-1.8l-0.1-0.6L115.9,56.9z M116.6,75.3l-3.5-6l10-6l3.5,6l-2.2,1.3l-1.9-3.2l-1.6,0.9l1.8,3l-2.2,1.3l-1.8-3 l-1.9,1.1l1.9,3.2L116.6,75.3z M130.1,76.2c-0.6-0.5-1.2-0.7-1.9-0.5c-0.7,0.2-1.4,0.7-2.2,1.5c-1.5,1.7-1.6,3.1-0.3,4.2 c0.4,0.3,0.8,0.6,1.3,0.8c0.5,0.2,0.9,0.4,1.4,0.6l-1.8,2c-1-0.3-2-0.9-2.9-1.7c-1.3-1.2-2-2.5-2-3.8c0-1.4,0.6-2.8,1.9-4.2 c0.8-0.9,1.7-1.5,2.6-1.9c0.9-0.4,1.9-0.5,2.9-0.3c1,0.2,1.9,0.7,2.7,1.5c0.9,0.8,1.7,1.8,2.2,3l-2.4,1.2c-0.2-0.4-0.4-0.9-0.6-1.2 C130.8,76.9,130.5,76.5,130.1,76.2z M143.9,87c-0.7,1.8-1.7,3.1-3,3.7c-1.3,0.6-2.8,0.6-4.5-0.1c-1.7-0.7-2.8-1.6-3.4-2.9	c-0.5-1.3-0.5-2.9,0.2-4.7c0.7-1.8,1.7-3,3-3.6c1.3-0.6,2.8-0.6,4.5,0.1c1.7,0.7,2.9,1.6,3.4,2.9C144.7,83.6,144.6,85.2,143.9,87z M136.4,84.1c-0.8,2.1-0.5,3.4,1,4c0.7,0.3,1.4,0.2,2-0.1c0.6-0.4,1-1.1,1.5-2.2c0.4-1.1,0.5-2,0.4-2.6c-0.2-0.7-0.6-1.1-1.3-1.4 C138.3,81.2,137.2,82,136.4,84.1z M151.1,89.1l0.1,4.2l-3.2,0.1l-0.2-11.7l3.8-0.1c3.2-0.1,4.8,1.1,4.8,3.4c0,1.4-0.6,2.4-1.9,3.2	l3.5,5l-3.6,0.1l-2.5-4.2L151.1,89.1z M151.1,86.7l0.6,0c1.1,0,1.6-0.5,1.6-1.5c0-0.8-0.6-1.2-1.6-1.2l-0.6,0L151.1,86.7z M170,83.1c0.7,1.8,0.7,3.4,0.1,4.8c-0.6,1.4-1.9,2.4-3.7,3.1l-3.5,1.3l-4.1-10.9l3.8-1.4c1.8-0.7,3.3-0.7,4.6-0.2	C168.4,80.3,169.4,81.4,170,83.1z M167,84.3c-0.4-1-0.9-1.7-1.4-2c-0.6-0.3-1.3-0.4-2.1,0l-0.9,0.3l2.3,6.1l0.7-0.2	c0.9-0.3,1.5-0.8,1.7-1.5C167.5,86.3,167.4,85.4,167,84.3z M176.7,85.7l-7-9.4l2.5-1.9l7,9.4L176.7,85.7z M190.5,71l-2.4,3.3 l-9.2-1.4l0,0.1c1.1,0.7,1.9,1.2,2.5,1.6l4.3,3.1l-1.6,2.3l-9.4-6.9l2.4-3.3l9.1,1.3l0,0c-1-0.6-1.8-1.2-2.4-1.6l-4.3-3.1l1.7-2.3	L190.5,71z M187.6,58.6l1.2-4.9l6.1,1.5c0.1,1.4,0,3-0.4,4.6c-0.4,1.7-1.3,3-2.5,3.7c-1.2,0.7-2.8,0.8-4.7,0.4	c-1.8-0.4-3.1-1.3-3.9-2.6c-0.8-1.3-0.9-2.9-0.5-4.8c0.2-0.7,0.4-1.4,0.7-2c0.3-0.6,0.6-1.1,0.9-1.5l2.2,1.6 c-0.6,0.7-1,1.6-1.3,2.5c-0.2,0.9-0.1,1.7,0.4,2.3c0.5,0.6,1.2,1.1,2.3,1.3c1.1,0.3,1.9,0.2,2.6-0.1c0.7-0.3,1.1-0.9,1.3-1.7 c0.1-0.5,0.2-0.9,0.2-1.3l-1.8-0.4l-0.5,2L187.6,58.6z M132.4,23.3l-1.9-1.3l-2.9,2.5l1,2l-2.6,2.3l-4.8-11.4l3.2-2.7l10.6,6.4 L132.4,23.3z M128.4,20.5l-1.6-1.1c-0.4-0.2-0.8-0.6-1.4-1c-0.6-0.4-1-0.7-1.2-0.9c0.1,0.2,0.4,0.6,0.7,1.2 c0.3,0.6,0.9,1.7,1.7,3.4L128.4,20.5z M132.6,9.6l3.8-1.4c1.5-0.5,2.7-0.7,3.6-0.5c0.9,0.2,1.5,0.7,1.8,1.7 c0.2,0.6,0.3,1.2,0.1,1.7c-0.2,0.5-0.5,1-0.9,1.3l0,0.1c0.7-0.1,1.3,0.1,1.8,0.4s0.8,0.8,1.1,1.5c0.4,1,0.3,1.9-0.3,2.8 c-0.5,0.8-1.5,1.5-2.7,2l-4.3,1.5L132.6,9.6z M137.1,12.7l0.9-0.3c0.4-0.2,0.7-0.4,0.9-0.6c0.2-0.3,0.2-0.6,0.1-0.9 c-0.2-0.6-0.8-0.8-1.7-0.4l-0.8,0.3L137.1,12.7z M137.9,14.9l0.8,2.3l1-0.4c0.9-0.3,1.2-0.9,1-1.7c-0.1-0.4-0.4-0.6-0.7-0.7 c-0.3-0.1-0.7-0.1-1.2,0.1L137.9,14.9z M158.4,11.5c-0.1,2-0.6,3.4-1.6,4.4c-1,1-2.4,1.5-4.3,1.4c-1.8-0.1-3.2-0.6-4.2-1.7	c-0.9-1.1-1.4-2.6-1.3-4.5c0.1-1.9,0.6-3.4,1.6-4.4c1-1,2.4-1.5,4.3-1.4c1.9,0.1,3.3,0.6,4.2,1.7C158,8,158.4,9.5,158.4,11.5z M150.3,11.3c-0.1,2.3,0.7,3.4,2.3,3.5c0.8,0,1.4-0.2,1.8-0.8c0.4-0.5,0.6-1.4,0.7-2.5c0-1.2-0.1-2-0.5-2.6 c-0.4-0.6-0.9-0.9-1.7-0.9C151.2,7.9,150.4,9,150.3,11.3z M165,15.5l-1.7,3.9l-2.9-1.3l4.7-10.7l3.5,1.5c2.9,1.3,3.9,3,3,5.1 c-0.5,1.2-1.6,1.9-3.1,2.1l1.1,6l-3.3-1.4l-0.6-4.9L165,15.5z M166,13.3l0.5,0.2c1,0.4,1.7,0.2,2.1-0.7c0.3-0.7,0-1.3-1-1.8 l-0.6-0.2L166,13.3z M174.4,26.7l-2.3-2.1l6.1-6.7l-2.1-1.9l1.7-1.9l6.5,6l-1.7,1.9l-2.1-1.9L174.4,26.7z"/> <polygon id="abort_cross" visibility ="hidden" fill="#FF2200" points="171.9,37.8 163.6,29.5 151.7,41.4 139.8,29.5 131.5,37.8 143.4,49.7 131.5,61.6 139.8,69.9 151.7,58 163.6,69.9 171.9,61.6 160,49.7"/>	<circle class="mouseover" visibility ="hidden" opacity="0.05" fill="#FFFFFF" cx="151.4" cy="49.7" r="49.7"/></g><g id="button-record" onClick="on_record_button()"> <g id="record_off" class="button" >  <circle class="shadow" opacity="0.15" cx="50.4" cy="58.3" r="49.7"/> <path fill="#5D3729" d="M49.7,98.8c-27.1,0-49-21.9-49-49s21.9-49,49-49s49,21.9,49,49S76.9,98.8,49.7,98.8z"/> <path fill="#1A1A1A" d="M49.7,1.4c26.7,0,48.3,21.7,48.3,48.3S76.5,98.1,49.7,98.1S1.4,76.5,1.4,49.7S23,1.4,49.7,1.4 M49.7,0           C22.3,0,0,22.3,0,49.7s22.3,49.7,49.7,49.7s49.7-22.3,49.7-49.7S77.2,0,49.7,0L49.7,0z"/> <linearGradient id="rec_off1" gradientUnits="userSpaceOnUse" x1="49.7368" y1="-879.7368" x2="49.7368" y2="-831.4211" gradientTransform="matrix(1 0 0 -1 0 -830)"> <stop  offset="0" style="stop-color:#FFFFFF;stop-opacity:0.25"/> <stop  offset="1" style="stop-color:#FFFFFF"/> </linearGradient> <path opacity="0.15" fill="url(#rec_off1)" d="M98.1,49.7H1.4l0,0C1.4,23,23,1.4,49.7,1.4l0,0 C76.6,1.4,98.1,23,98.1,49.7L98.1,49.7z"/> <circle opacity="0.5" fill="none" stroke="#FFFFFF" stroke-width="11.0527" stroke-miterlimit="10" cx="49.7" cy="49.7" r="23.3"/> <path class="mouseover" visibility="hidden" opacity="0.1" fill="#FFFFFF" d="M49.7,98.8c-27.1,0-49-21.9-49-49s21.9-49,49-49s49,21.9,49,49 S76.9,98.8,49.7,98.8z"/> </g> <g id="record_on" class="button" visibility="hidden" > <path fill="#FF2200" d="M49.7,98.8c-27.1,0-49-21.9-49-49s21.9-49,49-49s49,21.9,49,49S76.9,98.8,49.7,98.8z"/> <path fill="#1A1A1A" d="M49.7,1.4c26.7,0,48.3,21.7,48.3,48.3S76.5,98.1,49.7,98.1S1.4,76.5,1.4,49.7S23,1.4,49.7,1.4 M49.7,0 C22.3,0,0,22.3,0,49.7s22.3,49.7,49.7,49.7s49.7-22.3,49.7-49.7S77.2,0,49.7,0L49.7,0z"/><circle opacity="0.5" fill="none" stroke="#FFFFFF" stroke-width="11.0527" stroke-miterlimit="10" cx="49.7" cy="49.7" r="23.3"/><path class="mouseover" visibility="hidden" opacity="0.2" fill="#FFFFFF" d="M49.7,98.8c-27.1,0-49-21.9-49-49s21.9-49,49-49s49,21.9,49,49 S76.9,98.8,49.7,98.8z"/> </g> </g> </svg>
    </div>

<div id="track0">
    <div>
         <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="100%"
             height="100%" viewBox="0 0 320 55" xml:space="preserve">
        <g id="divider">
            <rect x="0" y="1" opacity="5.000000e-02" fill="#FFFFFF" width="320" height="1"/>
            <rect x="0" fill="#1A1A1A" width="320" height="1"/>
        </g>
        <rect id="underline" x="6" y="30" fill="#404040" width="259" height="1"/>
        <g>
            <text transform="matrix(1 0 0 1 7.3999 24.2002)" fill="#808080" font-family="'Open Sans'" font-size="19px">MASTER</text>
        </g>
        <g id="mute">
            <g id="master-mute-off" class="button">
                <path class="shadow" opacity="0.15" d="M314.4,51.2c0,1-0.8,1.8-1.8,1.8h-39c-1,0-1.8-0.8-1.8-1.8
                    v-4.6h42.7V51.2z"/>

                    <linearGradient id="mmGrad" gradientUnits="userSpaceOnUse" x1="1720.0585" y1="184.6258" x2="1720.0585" y2="141.3522" gradientTransform="matrix(1 0 0 -1 -1427 191)">
                    <stop  offset="0" style="stop-color:#FFFFFF"/>
                    <stop  offset="1" style="stop-color:#D9D9D9"/>
                </linearGradient>
                <path fill="url(#mmGrad)" d="M273.6,49.6c-1.2,0-2.1-1-2.1-2.1v-39c0-1.2,1-2.1,2.1-2.1h39c1.2,0,2.1,1,2.1,2.1v39
                    c0,1.2-1,2.1-2.1,2.1H273.6z"/>
                <g>
                    <path fill="#54362A" d="M293.1,31.9L293.1,31.9l4.2-10h2.2v12.3h-1.8V25h-0.1l-3.9,9.1h-1.2l-4-9.5h-0.1v9.5h-1.8V21.9h2.3
                        L293.1,31.9z"/>
                </g>
                <path class="mouseover" visibility="hidden" opacity="0.5"  fill="#FFFFFF" d="M273.6,49.6c-1.2,0-2.1-1-2.1-2.1v-39c0-1.2,1-2.1,2.1-2.1h39
                    c1.2,0,2.1,1,2.1,2.1v39c0,1.2-1,2.1-2.1,2.1H273.6z"/>
            </g>
            <g id="master-mute-on" class="button" visibility="hidden">
                <path fill="#F13F24" d="M273.6,49.6c-1.2,0-2.1-1-2.1-2.1v-39c0-1.2,1-2.1,2.1-2.1h39c1.2,0,2.1,1,2.1,2.1v39c0,1.2-1,2.1-2.1,2.1
                    H273.6z"/>
                <g>
                    <path fill="#FFFFFF" d="M293.1,31.9L293.1,31.9l4.2-10h2.2v12.3h-1.8V25h-0.1l-3.9,9.1h-1.2l-4-9.5h-0.1v9.5h-1.8V21.9h2.3
                        L293.1,31.9z"/>
                </g>
                <path class="mouseover" visibility="hidden" opacity="0.15" fill="#FFFFFF" d="M273.6,49.6c-1.2,0-2.1-1-2.1-2.1v-39c0-1.2,1-2.1,2.1-2.1h39
                    c1.2,0,2.1,1,2.1,2.1v39c0,1.2-1,2.1-2.1,2.1H273.6z"/>
            </g>
            <path id="border_1_" fill="#1A1A1A" d="M312.6,6.7c1,0,1.8,0.8,1.8,1.8v39c0,1-0.8,1.8-1.8,1.8h-39c-1,0-1.8-0.8-1.8-1.8v-39
                c0-1,0.8-1.8,1.8-1.8H312.6 M312.6,6.1h-39c-1.3,0-2.4,1.1-2.4,2.4v39c0,1.3,1.1,2.4,2.4,2.4h39c1.3,0,2.4-1.1,2.4-2.4v-39
                C315,7.2,313.9,6.1,312.6,6.1L312.6,6.1z"/>
        </g>
        <g id="clip_indicator">
            <g id="master-clip_off">
                <path fill="#404040" d="M237.5,48.6h18.9c3.7,0,6.6-3,6.6-6.6v-0.4c0-3.7-3-6.6-6.6-6.6h-18.9c-3.7,0-6.6,3-6.6,6.6V42
                    C230.9,45.7,233.8,48.6,237.5,48.6z"/>
                <path fill="#333333" d="M235.6,41.7c0-2.4,1.8-4,4-4c1.4,0,2.4,0.7,3,1.5l-0.8,0.5c-0.4-0.7-1.3-1.1-2.2-1.1c-1.7,0-3,1.3-3,3.2
                    c0,1.8,1.3,3.2,3,3.2c0.9,0,1.7-0.5,2.2-1.1l0.8,0.5c-0.7,0.9-1.6,1.5-3,1.5C237.3,45.8,235.6,44.1,235.6,41.7z M243.8,37.8h1v6.9
                    h3.6v0.9h-4.6V37.8z M249.8,37.8h1v7.8h-1V37.8z M252.6,37.8h3.1c1.6,0,2.4,1.1,2.4,2.3c0,1.3-0.9,2.3-2.4,2.3h-2.2v3.1h-1V37.8z
                     M255.6,38.7h-2v3h2c0.9,0,1.6-0.6,1.6-1.5S256.5,38.7,255.6,38.7z"/>
            </g>
            <g id="master-clip_on" visibility="hidden">
                <path fill="#922525" d="M237.5,48.6h18.9c3.7,0,6.6-3,6.6-6.6v-0.4c0-3.7-3-6.6-6.6-6.6h-18.9c-3.7,0-6.6,3-6.6,6.6V42
                    C230.9,45.7,233.8,48.6,237.5,48.6z"/>
                <path fill="#FFBFBF" d="M235.6,41.7c0-2.4,1.8-4,4-4c1.4,0,2.4,0.7,3,1.5l-0.8,0.5c-0.4-0.7-1.3-1.1-2.2-1.1c-1.7,0-3,1.3-3,3.2
                    c0,1.8,1.3,3.2,3,3.2c0.9,0,1.7-0.5,2.2-1.1l0.8,0.5c-0.7,0.9-1.6,1.5-3,1.5C237.3,45.8,235.6,44.1,235.6,41.7z M243.8,37.8h1v6.9
                    h3.6v0.9h-4.6V37.8z M249.8,37.8h1v7.8h-1V37.8z M252.6,37.8h3.1c1.6,0,2.4,1.1,2.4,2.3s-0.9,2.3-2.4,2.3h-2.2v3.1h-1V37.8z
                     M255.6,38.7h-2v3h2c0.9,0,1.6-0.6,1.6-1.5S256.5,38.7,255.6,38.7z"/>
            </g>
        </g>
        <text id="masterDb" text-anchor="end" transform="matrix(1 0 0 1 226 46)" fill="#FFFFFF" opacity="0.5" font-family="'Open Sans'" font-size="12px">xxdB</text>
        <rect class="hitbox" x="49" y="1" opacity="0" width="173" height="53.9" onClick="hitbox(0)"/>
        </svg>
    </div>

  <div class="trackRow2"></div>
    </div>
</div>
</div>

<br><div id="tracks"></div>
<div style="padding: 8px 6px 12px 6px; background-color: #333333;">
  <button onclick="wwr_req(40702)"
    style="
      width: 100%;
      padding: 10px 0;
      background: #262626;
      color: #9DA5A5;
      font-family: 'Open Sans', sans-serif;
      font-size: 0.95em;
      letter-spacing: 0.05em;
      border: 1px solid #404040;
      border-radius: 3px;
      cursor: pointer;
      user-select: none;
    "
    onmousedown="this.style.background='#1a1a1a'; this.style.color='#00FE95';"
    onmouseup="this.style.background='#262626'; this.style.color='#9DA5A5';"
    onmouseleave="this.style.background='#262626'; this.style.color='#9DA5A5';"
    ontouchstart="this.style.background='#1a1a1a'; this.style.color='#00FE95';"
    ontouchend="this.style.background='#262626'; this.style.color='#9DA5A5';"
  >+ NEW TRACK</button>
</div>
</div>

<div id="backLoad" style= display:none>

<!-- TRACK ROW 1 -->

<element id=trackRow1Svg>
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="100%" height="100%"
	 viewBox="0 1 320 53" xml:space="preserve">
<rect class="trackrow1bg" y="1" width="320" height="54"/>
<path id="divider" fill="#333333" d="M0,0v1v27C0,13.1,12.1,1,27,1h293V0H0z"/>
<g class="recarm">
<g class="recarm button">
    <circle class="shadow" opacity="0.15" cx="27.2" cy="31.8" r="22.3"/>
    <path class="recarmBg" fill="#5D3729" d="M26.8,50c-12.2,0-22-9.8-22-22s9.8-22,22-22s22,9.8,22,22S39,50,26.8,50z"/>
    <path fill="#1A1A1A" d="M26.8,6.3c12,0,21.7,9.8,21.7,21.7s-9.7,21.7-21.7,21.7S5.1,40,5.1,28S14.8,6.3,26.8,6.3 M26.8,5.7
        C14.5,5.7,4.5,15.7,4.5,28s10,22.3,22.3,22.3s22.3-10,22.3-22.3S39.2,5.7,26.8,5.7L26.8,5.7z"/>
    <linearGradient id="SVGID_1_" gradientUnits="userSpaceOnUse" x1="26.8404" y1="-960.0018" x2="26.8404" y2="-938.2996" gradientTransform="matrix(1 0 0 -1 0 -932)">
        <stop offset="0" style="stop-color:#FFFFFF;stop-opacity:0.25"/>
        <stop offset="1" style="stop-color:#FFFFFF"/>
    </linearGradient>
    <path opacity="0.15" fill="url(#SVGID_1_)" d="M48.5,28H5.1l0,0c0-12,9.7-21.7,21.7-21.7l0,0C38.9,6.3,48.5,16,48.5,28L48.5,28z"/>
    <circle opacity="0.5" fill="none" stroke="#FFFFFF" stroke-width="4.9646" stroke-miterlimit="10" cx="26.8" cy="28" r="10.5"/>
    <text class="recarmLabel" x="26.8" y="32" text-anchor="middle" fill="#FFFFFF" font-family="'Open Sans'" font-size="9px" font-weight="700"></text>
    <circle class="mouseover" visibility="hidden" opacity="0.15" fill="#FFFFFF" cx="26.8" cy="28" r="22.3"/>
</g>
<!--
<g class="recarm-off button" >
	<circle class="shadow" opacity="0.15" cx="27.2" cy="31.8" r="22.3"/>
	<path fill="#5D3729" d="M26.8,50c-12.2,0-22-9.8-22-22s9.8-22,22-22s22,9.8,22,22S39,50,26.8,50z"/>
	<path fill="#1A1A1A" d="M26.8,6.3c12,0,21.7,9.8,21.7,21.7s-9.7,21.7-21.7,21.7S5.1,40,5.1,28S14.8,6.3,26.8,6.3 M26.8,5.7
		C14.5,5.7,4.5,15.7,4.5,28s10,22.3,22.3,22.3s22.3-10,22.3-22.3S39.2,5.7,26.8,5.7L26.8,5.7z"/>

		<linearGradient id="SVGID_1_" gradientUnits="userSpaceOnUse" x1="26.8404" y1="-960.0018" x2="26.8404" y2="-938.2996" gradientTransform="matrix(1 0 0 -1 0 -932)">
		<stop  offset="0" style="stop-color:#FFFFFF;stop-opacity:0.25"/>
		<stop  offset="1" style="stop-color:#FFFFFF"/>
	</linearGradient>
	<path opacity="0.15" fill="url(#SVGID_1_)" d="M48.5,28H5.1l0,0c0-12,9.7-21.7,21.7-21.7l0,0
		C38.9,6.3,48.5,16,48.5,28L48.5,28z"/>

		<circle opacity="0.5" fill="none" stroke="#FFFFFF" stroke-width="4.9646" stroke-miterlimit="10" cx="26.8" cy="28" r="10.5"/>
		<circle class="mouseover" visibility="hidden" opacity="0.15" fill="#FFFFFF" cx="26.8" cy="28" r="22.3"/>
</g>
<g class="recarm-on button">
	<path fill="#FF6600" d="M26.8,50.2C14.6,50.2,4.7,40.3,4.7,28S14.6,5.8,26.8,5.8S49,15.7,49,28S39.1,50.2,26.8,50.2z"/>
	<path fill="#1A1A1A" d="M26.8,6.1C38.9,6.1,48.7,16,48.7,28s-9.8,21.9-21.9,21.9S5,40.1,5,28S14.8,6.1,26.8,6.1 M26.8,5.5
		C14.4,5.5,4.3,15.6,4.3,28s10.1,22.5,22.5,22.5S49.3,40.4,49.3,28S39.2,5.5,26.8,5.5L26.8,5.5z"/>

		<circle opacity="0.5" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-miterlimit="10" cx="26.8" cy="28" r="10.5"/>
        <text x="26.8" y="32" text-anchor="middle" fill="#FFFFFF" font-family="'Open Sans'" font-size="17px" font-weight="700">1</text>
		<circle class="mouseover" visibility="hidden" opacity="0.15" fill="#FFFFFF" cx="26.8" cy="28" r="22.3"/>
</g>
<g class="recarm-on2 button">
    <path fill="#FF2200" d="M26.8,50.2C14.6,50.2,4.7,40.3,4.7,28S14.6,5.8,26.8,5.8S49,15.7,49,28S39.1,50.2,26.8,50.2z"/>
    <path fill="#1A1A1A" d="M26.8,6.1C38.9,6.1,48.7,16,48.7,28s-9.8,21.9-21.9,21.9S5,40.1,5,28S14.8,6.1,26.8,6.1 M26.8,5.5
        C14.4,5.5,4.3,15.6,4.3,28s10.1,22.5,22.5,22.5S49.3,40.4,49.3,28S39.2,5.5,26.8,5.5L26.8,5.5z"/>
    <circle opacity="0.5" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-miterlimit="10" cx="26.8" cy="28" r="10.5"/>
    <text x="26.8" y="32" text-anchor="middle" fill="#FFFFFF" font-family="'Open Sans'" font-size="11px" font-weight="700">2</text>
    <circle class="mouseover" visibility="hidden" opacity="0.15" fill="#FFFFFF" cx="26.8" cy="28" r="22.3"/>
</g>
-->
</g>
<text class="trackNumber" transform="matrix(1 0 0 1 55.3999 48.2002)" fill="#FFFFFF" font-family="'Open Sans'" font-size="17px">88</text>
<rect id="underline" x="56" y="30" opacity="0.1" width="160" height="1"/>
<text class="trackName" transform="matrix(1 0 0 1 57.3999 24.2002)" fill="#1A1A1A" font-family="'Open Sans'" font-size="19px">Track Name</text>
<g class="solo button" >
	<g class="solo-off">
		<path class="shadow" opacity="0.15" d="M314.4,51.2c0,1-0.8,1.8-1.8,1.8h-39c-1,0-1.8-0.8-1.8-1.8
			v-4.6h42.7V51.2z"/>
			<linearGradient id="soloGrad" gradientUnits="userSpaceOnUse" x1="1720.0585" y1="773.3742" x2="1720.0585" y2="816.6478" gradientTransform="matrix(1 0 0 1 -1427 -767)">
			<stop  offset="0" style="stop-color:#FFFFFF"/>
			<stop  offset="1" style="stop-color:#D9D9D9"/>
		</linearGradient>
		<path fill="url(#soloGrad)" d="M273.6,49.6c-1.2,0-2.1-1-2.1-2.1v-39c0-1.2,1-2.1,2.1-2.1h39c1.2,0,2.1,1,2.1,2.1v39
			c0,1.2-1,2.1-2.1,2.1H273.6z"/>
		<path fill="#50542A" d="M295.7,31c0-0.5-0.2-1-0.6-1.4s-1.1-0.7-2.1-1c-1.2-0.3-2.2-0.8-2.9-1.3s-1-1.3-1-2.3c0-1,0.4-1.8,1.2-2.4
			s1.7-1,2.9-1c1.3,0,2.3,0.4,3.1,1.1s1.2,1.6,1.1,2.6v0.1h-1.6c0-0.7-0.2-1.3-0.7-1.7c-0.5-0.4-1.1-0.7-1.9-0.7s-1.3,0.2-1.8,0.5
			c-0.4,0.4-0.6,0.9-0.6,1.5c0,0.5,0.2,1,0.7,1.3c0.4,0.4,1.2,0.7,2.2,0.9c1.2,0.3,2.2,0.8,2.8,1.4c0.7,0.6,1,1.4,1,2.3
			c0,1-0.4,1.8-1.2,2.4c-0.8,0.6-1.8,0.9-3,0.9c-1.2,0-2.3-0.3-3.2-1c-0.9-0.7-1.3-1.5-1.3-2.7v-0.1h1.6c0,0.8,0.3,1.3,0.9,1.8
			c0.6,0.4,1.2,0.6,2,0.6s1.4-0.2,1.9-0.5C295.6,32.1,295.7,31.6,295.7,31z"/>
		<path class="mouseover" visibility="hidden" opacity="0.5" fill="#FFFFFF" d="M273.6,49.6c-1.2,0-2.1-1-2.1-2.1v-39c0-1.2,1-2.1,2.1-2.1h39
			c1.2,0,2.1,1,2.1,2.1v39c0,1.2-1,2.1-2.1,2.1H273.6z"/>
	</g>
	<g class="solo-on">
		<path fill="#F1C524" d="M273.6,49.6c-1.2,0-2.1-1-2.1-2.1v-39c0-1.2,1-2.1,2.1-2.1h39c1.2,0,2.1,1,2.1,2.1v39c0,1.2-1,2.1-2.1,2.1
			H273.6z"/>
		<path fill="#FFFFFF" d="M295.7,31c0-0.5-0.2-1-0.6-1.4s-1.1-0.7-2.1-1c-1.2-0.3-2.2-0.8-2.9-1.3s-1-1.3-1-2.3c0-1,0.4-1.8,1.2-2.4
			s1.7-1,2.9-1c1.3,0,2.3,0.4,3.1,1.1s1.2,1.6,1.1,2.6v0.1h-1.6c0-0.7-0.2-1.3-0.7-1.7c-0.5-0.4-1.1-0.7-1.9-0.7s-1.3,0.2-1.8,0.5
			c-0.4,0.4-0.6,0.9-0.6,1.5c0,0.5,0.2,1,0.7,1.3c0.4,0.4,1.2,0.7,2.2,0.9c1.2,0.3,2.2,0.8,2.8,1.4c0.7,0.6,1,1.4,1,2.3
			c0,1-0.4,1.8-1.2,2.4c-0.8,0.6-1.8,0.9-3,0.9c-1.2,0-2.3-0.3-3.2-1c-0.9-0.7-1.3-1.5-1.3-2.7v-0.1h1.6c0,0.8,0.3,1.3,0.9,1.8
			c0.6,0.4,1.2,0.6,2,0.6s1.4-0.2,1.9-0.5C295.6,32.1,295.7,31.6,295.7,31z"/>
		<path class="mouseover" visibility="hidden" opacity="0.2" fill="#FFFFFF" d="M273.6,49.6c-1.2,0-2.1-1-2.1-2.1v-39c0-1.2,1-2.1,2.1-2.1h39
			c1.2,0,2.1,1,2.1,2.1v39c0,1.2-1,2.1-2.1,2.1H273.6z"/>
	</g>
	<path id="border" fill="#1A1A1A" d="M312.6,6.7c1,0,1.8,0.8,1.8,1.8v39c0,1-0.8,1.8-1.8,1.8h-39c-1,0-1.8-0.8-1.8-1.8v-39
		c0-1,0.8-1.8,1.8-1.8H312.6 M312.6,6.1h-39c-1.3,0-2.4,1.1-2.4,2.4v39c0,1.3,1.1,2.4,2.4,2.4h39c1.3,0,2.4-1.1,2.4-2.4v-39
		C315,7.2,313.9,6.1,312.6,6.1L312.6,6.1z"/>
</g>
<g class="mute button">
	<g class="mute-off">
		<path class="shadow" opacity="0.15" d="M265.4,51.2c0,1-0.8,1.8-1.8,1.8h-39c-1,0-1.8-0.8-1.8-1.8
			v-4.6h42.7V51.2z"/>

			<linearGradient id="muteOffGrad" gradientUnits="userSpaceOnUse" x1="1671.0585" y1="184.6258" x2="1671.0585" y2="141.3522" gradientTransform="matrix(1 0 0 -1 -1427 191)">
			<stop  offset="0" style="stop-color:#FFFFFF"/>
			<stop  offset="1" style="stop-color:#D9D9D9"/>
		</linearGradient>
		<path fill="url(#muteOffGrad)" d="M224.6,49.6c-1.2,0-2.1-1-2.1-2.1v-39c0-1.2,1-2.1,2.1-2.1h39c1.2,0,2.1,1,2.1,2.1v39
			c0,1.2-1,2.1-2.1,2.1H224.6z"/>
			<path fill="#54362A" d="M244.1,31.9L244.1,31.9l4.2-10h2.2v12.3h-1.8V25h-0.1l-3.9,9.1h-1.2l-4-9.5h-0.1v9.5h-1.8V21.9h2.3
				L244.1,31.9z"/>
		<path fill="#1A1A1A" d="M263.6,6.7c1,0,1.8,0.8,1.8,1.8v39c0,1-0.8,1.8-1.8,1.8h-39c-1,0-1.8-0.8-1.8-1.8v-39
		c0-1,0.8-1.8,1.8-1.8H263.6 M263.6,6.1h-39c-1.3,0-2.4,1.1-2.4,2.4v39c0,1.3,1.1,2.4,2.4,2.4h39c1.3,0,2.4-1.1,2.4-2.4v-39
		C266,7.2,264.9,6.1,263.6,6.1L263.6,6.1z"/>
		<path class="mouseover" visibility="hidden" opacity="0.5" fill="#FFFFFF" d="M224.6,49.6c-1.2,0-2.1-1-2.1-2.1v-39c0-1.2,1-2.1,2.1-2.1h39
			c1.2,0,2.1,1,2.1,2.1v39c0,1.2-1,2.1-2.1,2.1H224.6z"/>
	</g>
	<g class="mute-on">
		<path fill="#F13F24" d="M224.6,49.6c-1.2,0-2.1-1-2.1-2.1v-39c0-1.2,1-2.1,2.1-2.1h39c1.2,0,2.1,1,2.1,2.1v39c0,1.2-1,2.1-2.1,2.1
			H224.6z"/>
			<path fill="#FFFFFF" d="M244.1,31.9L244.1,31.9l4.2-10h2.2v12.3h-1.8V25h-0.1l-3.9,9.1h-1.2l-4-9.5h-0.1v9.5h-1.8V21.9h2.3
				L244.1,31.9z"/>
		<path fill="#1A1A1A" d="M263.6,6.7c1,0,1.8,0.8,1.8,1.8v39c0,1-0.8,1.8-1.8,1.8h-39c-1,0-1.8-0.8-1.8-1.8v-39
		c0-1,0.8-1.8,1.8-1.8H263.6 M263.6,6.1h-39c-1.3,0-2.4,1.1-2.4,2.4v39c0,1.3,1.1,2.4,2.4,2.4h39c1.3,0,2.4-1.1,2.4-2.4v-39
		C266,7.2,264.9,6.1,263.6,6.1L263.6,6.1z"/>
		<path class="mouseover" opacity="0.15" fill="#FFFFFF" d="M224.6,49.6c-1.2,0-2.1-1-2.1-2.1v-39c0-1.2,1-2.1,2.1-2.1h39
			c1.2,0,2.1,1,2.1,2.1v39c0,1.2-1,2.1-2.1,2.1H224.6z"/>
	</g>

</g>
<g class="monitor button">
	<g class="monitor-auto">
		<path fill="#5F6666" d="M263.1,6h-38c-1.7,0-3,1.3-3,3v38c0,1.7,1.3,3,3,3h38c1.7,0,3-1.3,3-3V9C266.1,7.3,264.8,6,263.1,6z"/>
		<path fill="#ADB3B3" d="M250.7,29.5h-5.7l-3.2-3.2c-0.7-1.5-1.5-2.4-2.4-2.4c-2.1,0-3.8,4.6-3.8,10.3s1.7,10.3,3.8,10.3
			c0.9,0,1.8-0.9,2.4-2.4l3.2-3.2h5.7c1,0,1.9-2.1,1.9-4.7C252.6,31.6,251.8,29.5,250.7,29.5z M239.5,42.5c-0.7-0.7-1.9-3.5-1.9-8.3
			s1.2-7.7,1.9-8.3c0.7,0.7,1.9,3.5,1.9,8.3S240.1,41.8,239.5,42.5z"/>
		<path fill="#ADB3B3" d="M234.7,18.2h-2.1l-0.5,1.8h-1.7l2.4-8.4h1.7l2.4,8.3h-1.7L234.7,18.2z M233,16.9h1.4l-0.7-2.7h-0.1
			L233,16.9z M243.9,11.6v5.5c0,1-0.2,1.7-0.8,2.3c-0.5,0.5-1.3,0.8-2.1,0.8c-0.9,0-1.6-0.2-2.1-0.8c-0.5-0.5-0.8-1.3-0.8-2.3v-5.5
			h1.6v5.5c0,0.5,0.1,1,0.4,1.3c0.2,0.3,0.5,0.4,1,0.4c0.4,0,0.7-0.1,1-0.4c0.2-0.3,0.4-0.7,0.4-1.3v-5.5L243.9,11.6L243.9,11.6z
			 M250.7,12.9h-1.9V20h-1.6v-7.1h-1.9v-1.3h5.5L250.7,12.9C250.8,12.9,250.7,12.9,250.7,12.9z M257.9,17c0,1-0.4,1.7-0.9,2.3
			c-0.5,0.5-1.3,0.9-2.2,0.9c-0.9,0-1.6-0.3-2.2-0.9c-0.5-0.5-0.9-1.3-0.9-2.3v-2.3c0-1,0.3-1.8,0.9-2.3s1.3-0.9,2.2-0.9
			c0.9,0,1.6,0.3,2.3,0.9c0.5,0.5,0.9,1.3,0.9,2.3L257.9,17L257.9,17z M256.3,14.6c0-0.6-0.1-1.1-0.4-1.4s-0.6-0.5-1.1-0.5
			s-0.9,0.2-1,0.5s-0.4,0.8-0.4,1.4V17c0,0.6,0.1,1.1,0.4,1.4s0.6,0.5,1.1,0.5s0.9-0.2,1.1-0.5c0.2-0.3,0.4-0.8,0.4-1.4L256.3,14.6
			L256.3,14.6z"/>
	</g>
	<g class="monitor-on">
		<path fill="#5F6666" d="M263.1,6h-38c-1.7,0-3,1.3-3,3v38c0,1.7,1.3,3,3,3h38c1.7,0,3-1.3,3-3V9C266.1,7.3,264.8,6,263.1,6z"/>
		<path fill="#ADB3B3" d="M250.7,23.2h-5.7l-3.2-3.2c-0.7-1.5-1.5-2.4-2.4-2.4c-2.1,0-3.8,4.6-3.8,10.3s1.7,10.3,3.8,10.3
			c0.9,0,1.8-0.9,2.4-2.4l3.2-3.2h5.7c1,0,1.9-2.1,1.9-4.7C252.6,25.3,251.8,23.2,250.7,23.2z M239.5,36.2c-0.7-0.7-1.9-3.5-1.9-8.3
			s1.2-7.7,1.9-8.3c0.7,0.7,1.9,3.5,1.9,8.3S240.1,35.6,239.5,36.2z"/>
	</g>
	<g class="monitor-off">
		<path fill="#9DA5A5" d="M225.1,49.5c-1.4,0-2.5-1.1-2.5-2.5V9c0-1.4,1.1-2.5,2.5-2.5h38c1.4,0,2.5,1.1,2.5,2.5v38
			c0,1.4-1.1,2.5-2.5,2.5H225.1z"/>
		<path fill="#5F6666" d="M263.1,7c1.1,0,2,0.9,2,2v38c0,1.1-0.9,2-2,2h-38c-1.1,0-2-0.9-2-2V9c0-1.1,0.9-2,2-2H263.1 M263.1,6h-38
			c-1.7,0-3,1.3-3,3v38c0,1.7,1.3,3,3,3h38c1.7,0,3-1.3,3-3V9C266.1,7.3,264.8,6,263.1,6L263.1,6z"/>
		<path fill="#5F6666" d="M250.7,23.2h-5.7l-3.2-3.2c-0.7-1.5-1.5-2.4-2.4-2.4c-0.8,0-1.6,0.7-2.2,1.9h2.2c0.2,0.2,0.4,0.5,0.7,1.2
			l0.1,0.3l0.2,0.2l3.2,3.2l0.5,0.5h0.7h5.2c0.2,0.4,0.5,1.4,0.5,2.9c0,1.5-0.3,2.4-0.5,2.9h-5.2h-0.7l-0.5,0.5l-3.2,3.2l-0.2,0.2
			l-0.1,0.3c-0.3,0.7-0.5,1-0.7,1.2l0,0h-2.2c0.6,1.2,1.3,1.9,2.2,1.9c0.9,0,1.8-0.9,2.4-2.4l3.2-3.2h5.7c1,0,1.9-2.1,1.9-4.7
			C252.6,25.3,251.8,23.2,250.7,23.2z"/>
	</g>
	<path class="mouseover" visibility="hidden" opacity="0.2" fill="#FFFFFF" d="M224.6,49.6c-1.2,0-2.1-1-2.1-2.1v-39c0-1.2,1-2.1,2.1-2.1h39
			c1.2,0,2.1,1,2.1,2.1v39c0,1.2-1,2.1-2.1,2.1H224.6z"/>
</g>
<polygon class="folder_icon" fill="#616666" points="88,39 85.3,36 80,36 80,39 80,48 94,48 94,39 "/>
<g id="clip_indicator">
	<g id="clip_off">
		<path opacity="0.1" d="M158,48.6h18.9c3.7,0,6.6-3,6.6-6.6v-0.4c0-3.7-3-6.6-6.6-6.6H158c-3.7,0-6.6,3-6.6,6.6V42
			C151.4,45.7,154.3,48.6,158,48.6z"/>
        //<rect class="vuBar" x="151.4" y="37.6" width="0" height="11" fill="#00FE95" opacity="0.7"/>
		<path fill="#9DA5A5" d="M156.1,41.7c0-2.4,1.8-4,4-4c1.4,0,2.4,0.7,3,1.5l-0.8,0.5c-0.4-0.7-1.3-1.1-2.2-1.1c-1.7,0-3,1.3-3,3.2
			c0,1.8,1.3,3.2,3,3.2c0.9,0,1.7-0.5,2.2-1.1l0.8,0.5c-0.7,0.9-1.6,1.5-3,1.5C157.8,45.8,156.1,44.1,156.1,41.7z M164.3,37.8h1v6.9
			h3.6v0.9h-4.6V37.8z M170.3,37.8h1v7.8h-1V37.8z M173.1,37.8h3.1c1.6,0,2.4,1.1,2.4,2.3c0,1.3-0.9,2.3-2.4,2.3H174v3.1h-1V37.8z
			 M176.1,38.7h-2v3h2c0.9,0,1.6-0.6,1.6-1.5S177,38.7,176.1,38.7z"/>
	</g>
	<g class="clip_on" visibility="hidden">
		<path fill="#922525" d="M158,48.6h18.9c3.7,0,6.6-3,6.6-6.6v-0.4c0-3.7-3-6.6-6.6-6.6H158c-3.7,0-6.6,3-6.6,6.6V42
			C151.4,45.7,154.3,48.6,158,48.6z"/>
		<path fill="#FFBFBF" d="M156.1,41.7c0-2.4,1.8-4,4-4c1.4,0,2.4,0.7,3,1.5l-0.8,0.5c-0.4-0.7-1.3-1.1-2.2-1.1c-1.7,0-3,1.3-3,3.2
			c0,1.8,1.3,3.2,3,3.2c0.9,0,1.7-0.5,2.2-1.1l0.8,0.5c-0.7,0.9-1.6,1.5-3,1.5C157.8,45.8,156.1,44.1,156.1,41.7z M164.3,37.8h1v6.9
			h3.6v0.9h-4.6V37.8z M170.3,37.8h1v7.8h-1V37.8z M173.1,37.8h3.1c1.6,0,2.4,1.1,2.4,2.3s-0.9,2.3-2.4,2.3H174v3.1h-1V37.8z
			 M176.1,38.7h-2v3h2c0.9,0,1.6-0.6,1.6-1.5S177,38.7,176.1,38.7z"/>
	</g>
</g>
<g id="r_indicator">
	<g id="r_off">
		<circle opacity="0.1" cx="192" cy="41.8" r="6.8"/>
		<path fill="#9DA5A5" d="M192,42.7h-1.6v3.2h-1v-8h3.2c1.5,0,2.5,0.9,2.5,2.4c0,1.4-1,2.2-2.1,2.3l2.2,3.3H194L192,42.7z
			 M192.5,38.8h-2.1v3.1h2.1c0.9,0,1.6-0.6,1.6-1.5S193.5,38.8,192.5,38.8z"/>
	</g>
	<g class="r_on" visibility="hidden">
		<circle fill="#7C8040" cx="192" cy="41.8" r="6.8"/>
		<path fill="#EEFF00" d="M192,42.7h-1.6v3.2h-1v-8h3.2c1.5,0,2.5,0.9,2.5,2.4c0,1.4-1,2.2-2.1,2.3l2.2,3.3H194L192,42.7z
			 M192.5,38.8h-2.1v3.1h2.1c0.9,0,1.6-0.6,1.6-1.5S193.5,38.8,192.5,38.8z"/>
	</g>
</g>

	<g id="s_off">
		<circle opacity="0.1" cx="207.2" cy="41.8" r="6.8"/>
		<path fill="#9DA5A5" d="M204.9,44c0.5,0.6,1.4,1.1,2.5,1.1c1.4,0,1.9-0.8,1.9-1.4c0-1-1-1.2-2-1.5c-1.3-0.3-2.7-0.7-2.7-2.3
			c0-1.3,1.2-2.2,2.7-2.2c1.2,0,2.2,0.4,2.8,1.1l-0.6,0.7c-0.6-0.7-1.4-1-2.3-1c-1,0-1.6,0.5-1.6,1.3c0,0.8,0.9,1,1.9,1.3
			c1.3,0.3,2.8,0.8,2.8,2.4c0,1.2-0.8,2.4-3,2.4c-1.4,0-2.4-0.5-3.1-1.3L204.9,44z"/>
	</g>
	<g class="s_on" visibility="hidden">
		<circle fill="#437480" cx="207.2" cy="41.8" r="6.8"/>
		<path fill="#00D0FF" d="M204.9,44c0.5,0.6,1.4,1.1,2.5,1.1c1.4,0,1.9-0.8,1.9-1.4c0-1-1-1.2-2-1.5c-1.3-0.3-2.7-0.7-2.7-2.3
			c0-1.3,1.2-2.2,2.7-2.2c1.2,0,2.2,0.4,2.8,1.1l-0.6,0.7c-0.6-0.7-1.4-1-2.3-1c-1,0-1.6,0.5-1.6,1.3c0,0.8,0.9,1,1.9,1.3
			c1.3,0.3,2.8,0.8,2.8,2.4c0,1.2-0.8,2.4-3,2.4c-1.4,0-2.4-0.5-3.1-1.3L204.9,44z"/>
	</g>
    <text class="meterReadout" text-anchor="end" transform="matrix(1 0 0 1 147 46)" fill="#FFFFFF" opacity="0.75" font-family="'Open Sans'" font-size="11px">dB</text>
    <rect class="hitbox" x="49" y="1" opacity="0" width="173" height="53.9" onClick="hitbox(event.target.id)"/>
    <rect class="nameHitbox" x="57" y="1" width="160" height="28" fill="transparent" pointer-events="all" style="cursor:text"/>
    <rect class="trackNumHitbox" x="55" y="30" width="25" height="20" fill="transparent" pointer-events="all" style="cursor:text"/>
</svg></element>

  <!-- TRACK ROW 2 -->

<!-- TRACK ROW 2 -->

<element id=trackRow2Svg>
<svg version="1.1" class="faderSvg" display="block" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="100%" height="100%" viewBox="0 1 320 0.0001" xml:space="preserve">
<rect x="0" fill="#333333" width="320" height="36"/>

<!-- pan knob (left side, cx=20) -->
<g class="panKnob" style="cursor:pointer">
  <circle cx="20" cy="18" r="14" fill="#262626" stroke="#404040" stroke-width="1"/>
  <circle cx="20" cy="18" r="11" fill="#1a1a1a"/>
  <!-- pan indicator line, rotated by JS. default = straight up = center -->
  <line class="panLine" x1="20" y1="18" x2="20" y2="7" stroke="#9DA5A5" stroke-width="2" stroke-linecap="round"/>
  <text class="panLabel" text-anchor="middle" x="20" y="35" fill="#545454" font-family="'Open Sans'" font-size="7px">PAN</text>
</g>

<!-- fader track, shifted right to make room for pan knob -->
<rect id="fader_track" x="46" y="16.7" opacity="0.5" fill="#1A1A1A" width="236" height="4"/>
<g class="fader">
	<g>
			<linearGradient id="fGrad1" gradientUnits="userSpaceOnUse" x1="245.0833" y1="-114.0833" x2="245.0833" y2="-106.0833" gradientTransform="matrix(6.123234e-17 -1 -1 -6.123234e-17 -68.0833 263.0833)">
			<stop  offset="0" style="stop-color:#212121"/>
			<stop  offset="1" style="stop-color:#949494"/>
		</linearGradient>
		<rect x="38" y="0.5" fill="url(#fGrad1)" width="8" height="35"/>

			<linearGradient id="fGrad2" gradientUnits="userSpaceOnUse" x1="245.0833" y1="-106.0833" x2="245.0833" y2="-92.0833" gradientTransform="matrix(6.123234e-17 -1 -1 -6.123234e-17 -68.0833 263.0833)">
			<stop  offset="0" style="stop-color:#FFFFFF"/>
			<stop  offset="0.9991" style="stop-color:#7A7A7A"/>
		</linearGradient>
		<path fill="url(#fGrad2)" d="M26,0.5h12v35H26c-1.1,0-2-0.9-2-2v-31C24,1.4,24.9,0.5,26,0.5z"/>

			<linearGradient id="fGrad3" gradientUnits="userSpaceOnUse" x1="245.0833" y1="-91.0833" x2="245.0833" y2="-77.0833" gradientTransform="matrix(6.123234e-17 -1 -1 -6.123234e-17 -68.0833 263.0833)">
			<stop  offset="0" style="stop-color:#9C9C9C"/>
			<stop  offset="1" style="stop-color:#4D4D4D"/>
		</linearGradient>
		<path fill="url(#fGrad3)" d="M21,35.5c1.1,0,2-0.9,2-2v-31c0-1.1-0.9-2-2-2H9v35H21z"/>

			<linearGradient id="fGrad4" gradientUnits="userSpaceOnUse" x1="245.0833" y1="-77.0833" x2="245.0833" y2="-69.0833" gradientTransform="matrix(6.123234e-17 -1 -1 -6.123234e-17 -68.0833 263.0833)">
			<stop  offset="0" style="stop-color:#FFFFFF"/>
			<stop  offset="0.1231" style="stop-color:#F2F2F2"/>
			<stop  offset="0.3517" style="stop-color:#CFCFCF"/>
			<stop  offset="0.6607" style="stop-color:#979797"/>
			<stop  offset="1" style="stop-color:#525252"/>
		</linearGradient>
		<rect x="1" y="0.5" fill="url(#fGrad4)" width="8" height="35"/>
	</g>
	<path id="outline_1_" d="M1,0.5h20c1.1,0,2,0.9,2,2v31c0,1.1-0.9,2-2,2H1V0.5 M24,2.5c0-1.1,0.9-2,2-2h20v35H26c-1.1,0-2-0.9-2-2
		V2.5 M0.5,0v36H21c1.4,0,2.5-1.1,2.5-2.5c0,1.4,1.1,2.5,2.5,2.5h20.5V0H26c-1.4,0-2.5,1.1-2.5,2.5C23.5,1.1,22.4,0,21,0H0.5L0.5,0z"/>
	<path opacity="0.1" fill="#FFFFFF" d="M2,1.5h19c0.6,0,1,0.4,1,1v31c0,0.6-0.4,1-1,1H2V1.5 M25,2.5
		c0-0.6,0.4-1,1-1h19v33H26c-0.6,0-1-0.4-1-1V2.5 M1,0.5v35h20c1.1,0,2-0.9,2-2v-31c0-1.1-0.9-2-2-2H1L1,0.5z M24,2.5v31
		c0,1.1,0.9,2,2,2h20v-35H26C24.9,0.5,24,1.4,24,2.5L24,2.5z"/>
		<linearGradient id="fGrad5" gradientUnits="userSpaceOnUse" x1="245.0833" y1="-1061.0476" x2="245.0833" y2="-1058.0729" gradientTransform="matrix(6.123234e-17 -1 -1 -6.123234e-17 -1034.0834 263.0833)">
		<stop  offset="0" style="stop-color:#FFFFFF;stop-opacity:0"/>
		<stop  offset="0.5" style="stop-color:#FFFFFF"/>
	</linearGradient>
	<path opacity="0.33" fill="url(#fGrad5)" d="M26,35.5h1v-1h-1c-0.6,0-1-0.4-1-1v-31c0-0.6,0.4-1,1-1
		h1v-1h-1c-1,0-1.8,0.7-2,1.6v31.8C24.2,34.8,25,35.5,26,35.5z"/>
</g>

<!-- delete button (right side) — two states -->
<g class="trackDeleteBtn" style="cursor:pointer">
  <!-- normal state -->
  <g class="trackDeleteNormal">
    <rect x="285" y="2" width="32" height="32" rx="3" fill="#262626" stroke="#404040" stroke-width="1"/>
    <line x1="296" y1="12" x2="306" y2="24" stroke="#5a2a2a" stroke-width="2.5" stroke-linecap="round"/>
    <line x1="296" y1="24" x2="306" y2="12" stroke="#5a2a2a" stroke-width="2.5" stroke-linecap="round"/>
  </g>
  <!-- confirm state (shown by JS) -->
  <g class="trackDeleteConfirm" visibility="hidden">
    <rect x="285" y="2" width="32" height="32" rx="3" fill="#8B0000" stroke="#FF4444" stroke-width="1"/>
    <line x1="296" y1="12" x2="306" y2="24" stroke="#FF4444" stroke-width="2.5" stroke-linecap="round"/>
    <line x1="296" y1="24" x2="306" y2="12" stroke="#FF4444" stroke-width="2.5" stroke-linecap="round"/>
  </g>
  <!-- invisible hit rect covering full button area -->
  <rect x="285" y="2" width="32" height="32" rx="3" fill="transparent" pointer-events="all"/>
</g>

</svg>
</element>

<!-- SEND -->

<element id=trackSendSvg>
    <svg version="1.1"  display="block" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="100%"
         height="100%" viewBox="0 0 320 0.0001" xml:space="preserve">
    <rect class="sendPanelBg" fill="#333333" width="320" height="49"/>
    <path class="sendBg" fill="#262626" d="M244,0c-0.3,0-0.7,0-1,0v0H142h-17H27v0c-0.3,0-0.7,0-1,0C13.8,0,4,9.8,4,22s9.8,22,22,22
		c0.3,0,0.7,0,1,0v0h98h17h101v0c0.3,0,0.7,0,1,0c12.2,0,22-9.8,22-22S256.2,0,244,0z"/>
    <line class="sendLine" style="pointer-events:none" fill="none" opacity="0.5" stroke="#404040"  stroke-width="38" stroke-linecap="round" stroke-miterlimit="10" x1="27" y1="22" x2="130" y2="22"/>
    <text class="sendTitleText" style="pointer-events:none" transform="matrix(1 0 0 1 25 29)" fill="#A3A3A3" font-family="'Open Sans'" font-size="19px">Target Name</text>
    <text class="sDbText" style="pointer-events:none" text-anchor="end" transform="matrix(1 0 0 1 250 27)" fill="#A3A3A3" font-family="'Open Sans'" font-size="12px">xx dB</text>
	<circle class="sendThumb" opacity="0.5" fill="#808080" stroke="#262626" stroke-width="2" stroke-miterlimit="10" cx="26" cy="22" r="19"/>

        <g class="send_mute button">
            <g class="send_mute_off" visibility="visible">
                <path class="shadow" opacity="0.15" d="M314.4,45.2c0,1-0.8,1.8-1.8,1.8h-39c-1,0-1.8-0.8-1.8-1.8
                    v-4.6h42.7v4.6H314.4z"/>
                    <linearGradient id="smoGrad" gradientUnits="userSpaceOnUse" x1="1720.0585" y1="-785.3847" x2="1720.0585" y2="-828.6583" gradientTransform="matrix(1 0 0 -1 -1427 -785)">
                    <stop  offset="0" style="stop-color:#404040"/>
                    <stop  offset="1" style="stop-color:#333333"/>
                </linearGradient>
                <path fill="url(#smoGrad)" d="M273.6,43.6c-1.2,0-2.1-1-2.1-2.1v-39c0-1.2,1-2.1,2.1-2.1h39c1.2,0,2.1,1,2.1,2.1v39
                    c0,1.2-1,2.1-2.1,2.1H273.6z"/>
                <g>
                    <path fill="#805240" d="M293.1,25.9L293.1,25.9l4.2-10h2.2v12.3h-1.8V19h-0.1l-3.9,9.1h-1.2l-4-9.5h-0.1v9.5h-1.8V15.9h2.3
                        L293.1,25.9z"/>
                </g>
                <path class="mouseover" visibility="hidden" opacity="0.05" fill="#FFFFFF" d="M273.6,43.6c-1.2,0-2.1-1-2.1-2.1v-39 c0-1.2,1-2.1,2.1-2.1h39c1.2,0,2.1,1,2.1,2.1v39c0,1.2-1,2.1-2.1,2.1H273.6z"/>
            </g>
            <g class="send_mute_on" visibility="hidden">
                <path display="inline" fill="#F13F24" d="M273.6,43.6c-1.2,0-2.1-1-2.1-2.1v-39c0-1.2,1-2.1,2.1-2.1h39c1.2,0,2.1,1,2.1,2.1v39
                    c0,1.2-1,2.1-2.1,2.1H273.6z"/>
                <g display="inline">
                    <path fill="#FFFFFF" d="M293.1,25.9L293.1,25.9l4.2-10h2.2v12.3h-1.8V19h-0.1l-3.9,9.1h-1.2l-4-9.5h-0.1v9.5h-1.8V15.9h2.3
                        L293.1,25.9z"/>
                </g>
                <path class="mouseover" visibility="hidden" opacity="0" fill="#FFFFFF" d="M273.6,43.6 c-1.2,0-2.1-1-2.1-2.1v-39c0-1.2,1-2.1,2.1-2.1h39c1.2,0,2.1,1,2.1,2.1v39c0,1.2-1,2.1-2.1,2.1H273.6z"/>
            </g>
            <path fill="#1A1A1A" d="M312.6,0.7c1,0,1.8,0.8,1.8,1.8v39c0,1-0.8,1.8-1.8,1.8h-39c-1,0-1.8-0.8-1.8-1.8v-39
                c0-1,0.8-1.8,1.8-1.8H312.6 M312.6,0.1h-39c-1.3,0-2.4,1.1-2.4,2.4v39c0,1.3,1.1,2.4,2.4,2.4h39c1.3,0,2.4-1.1,2.4-2.4v-39
                C315,1.2,313.9,0.1,312.6,0.1L312.6,0.1z"/>
        </g>
    </svg>
</element>

   results : <span id="_results" style="font-size : 0.7em">Here</span><br><br>

</div>

<div id="tempoModal" style="
    display:none;
    position:fixed;
    top:0; left:0; right:0; bottom:0;
    background:rgba(0,0,0,0.7);
    z-index:1000;
    justify-content:center;
    align-items:center;
">
    <div style="position:absolute;top:0;left:0;right:0;bottom:0;" id="tempoModalBackdrop"></div>

    <div style="
        position:relative;
        background:#262626;
        border:1px solid #404040;
        border-radius:4px;
        width:85%;
        max-width:320px;
        z-index:1001;
        font-family:'Open Sans',sans-serif;
    ">
        <div style="padding:12px 16px;border-bottom:1px solid #404040;color:#9DA5A5;font-size:13px;letter-spacing:0.05em;">
            TEMPO & TIME SIGNATURE
        </div>

        <!-- tempo row -->
        <div style="display:flex;align-items:center;padding:14px 16px;border-bottom:1px solid #333;gap:12px;">
            <span style="color:#545454;font-size:12px;letter-spacing:0.05em;flex:1;">BPM</span>
            <div id="tempoDisplay" style="
                color:#00FE95;
                font-size:28px;
                font-weight:300;
                cursor:pointer;
                padding:4px 8px;
                border-radius:3px;
                border:1px solid transparent;
            ">120</div>
        </div>

        <!-- time sig row -->
        <div style="display:flex;align-items:center;padding:14px 16px;border-bottom:1px solid #333;gap:12px;">
            <span style="color:#545454;font-size:12px;letter-spacing:0.05em;flex:1;">TIME SIG</span>
            <div style="display:flex;flex-direction:column;align-items:center;gap:4px;cursor:pointer;" id="timeSigDisplay">
                <div id="timeSigNum" style="color:#A8A8A8;font-size:22px;font-weight:300;line-height:1;">4</div>
                <div style="width:24px;height:1px;background:#545454;"></div>
                <div id="timeSigDen" style="color:#A8A8A8;font-size:22px;font-weight:300;line-height:1;">4</div>
            </div>
        </div>

        <!-- inline edit area (hidden until tapped) -->
        <div id="tempoEditArea" style="display:none;padding:14px 16px;border-bottom:1px solid #333;">
            <div style="color:#545454;font-size:11px;letter-spacing:0.05em;margin-bottom:8px;" id="tempoEditLabel">BPM</div>
            <input id="tempoEditInput" type="number" style="
                width:100%;
                box-sizing:border-box;
                background:#1a1a1a;
                border:1px solid #00FE95;
                border-radius:3px;
                color:#00FE95;
                font-family:'Open Sans',sans-serif;
                font-size:24px;
                padding:8px 12px;
                outline:none;
            "/>
            <div style="display:flex;gap:1px;margin-top:8px;background:#404040;">
                <button id="tempoEditCancel" style="flex:1;padding:10px;background:#262626;color:#9DA5A5;font-family:'Open Sans',sans-serif;font-size:12px;border:none;cursor:pointer;">CANCEL</button>
                <button id="tempoEditConfirm" style="flex:1;padding:10px;background:#262626;color:#57FF86;font-family:'Open Sans',sans-serif;font-size:12px;border:none;cursor:pointer;">SET ›</button>
            </div>
        </div>

        <button id="tempoModalClose" style="
            width:100%;
            padding:12px;
            background:#262626;
            color:#545454;
            font-family:'Open Sans',sans-serif;
            font-size:12px;
            border:none;
            border-top:1px solid #404040;
            cursor:pointer;
            letter-spacing:0.05em;
            border-radius:0 0 4px 4px;
        ">CLOSE</button>
    </div>
</div>

<div id="projectModal" style="
    display:none;
    position:fixed;
    top:0; left:0; right:0; bottom:0;
    background:rgba(0,0,0,0.7);
    z-index:1000;
    justify-content:center;
    align-items:center;
">
    <!-- backdrop click closes -->
    <div style="position:absolute;top:0;left:0;right:0;bottom:0;" id="projectModalBackdrop"></div>

    <!-- modal panel -->
    <div style="
        position:relative;
        background:#262626;
        border:1px solid #404040;
        border-radius:4px;
        width:85%;
        max-width:400px;
        max-height:70vh;
        display:flex;
        flex-direction:column;
        z-index:1001;
    ">
        <!-- header -->
        <div style="padding:12px 16px;border-bottom:1px solid #404040;color:#9DA5A5;font-family:'Open Sans',sans-serif;font-size:13px;letter-spacing:0.05em;">
            LOAD PROJECT
        </div>

        <!-- scrollable list -->
        <div id="projectList" style="
            overflow-y:auto;
            flex:1;
            min-height:100px;
            max-height:50vh;
        "></div>

        <!-- footer buttons -->
        <div style="
            display:flex;
            border-top:1px solid #404040;
            gap:1px;
            background:#404040;
        ">
            <button id="btnNewProject" style="
                flex:1;
                padding:12px;
                background:#262626;
                color:#9DA5A5;
                font-family:'Open Sans',sans-serif;
                font-size:12px;
                border:none;
                cursor:pointer;
                letter-spacing:0.05em;
            ">+ NEW</button>
            <button id="btnConfirmLoad" style="
                flex:1;
                padding:12px;
                background:#262626;
                color:#57FF86;
                font-family:'Open Sans',sans-serif;
                font-size:12px;
                border:none;
                cursor:pointer;
                letter-spacing:0.05em;
            ">LOAD ›</button>
        </div>
    </div>
</div>

<div id="timeSelModal" style="
    display:none;
    position:fixed;
    top:0; left:0; right:0; bottom:0;
    background:rgba(0,0,0,0.7);
    z-index:1000;
    justify-content:center;
    align-items:center;
">
    <div style="position:absolute;top:0;left:0;right:0;bottom:0;" id="timeSelBackdrop"></div>
    <div style="
        position:relative;
        background:#262626;
        border:1px solid #404040;
        border-radius:4px;
        width:85%;
        max-width:320px;
        z-index:1001;
        font-family:'Open Sans',sans-serif;
    ">
        <div style="padding:12px 16px;border-bottom:1px solid #404040;color:#9DA5A5;font-size:13px;letter-spacing:0.05em;">
            SET TIME SELECTION
        </div>

        <div style="padding:14px 16px;border-bottom:1px solid #333;">
            <div style="color:#545454;font-size:11px;letter-spacing:0.05em;margin-bottom:8px;">FROM MARKER</div>
            <div id="timeSelFromList" style="display:flex;flex-wrap:wrap;gap:6px;"></div>
        </div>

        <div style="padding:14px 16px;border-bottom:1px solid #333;">
            <div style="color:#545454;font-size:11px;letter-spacing:0.05em;margin-bottom:8px;">TO MARKER</div>
            <div id="timeSelToList" style="display:flex;flex-wrap:wrap;gap:6px;"></div>
        </div>

        <div style="display:flex;border-top:1px solid #404040;gap:1px;background:#404040;">
            <button id="timeSelCancel" style="flex:1;padding:12px;background:#262626;color:#9DA5A5;font-family:'Open Sans',sans-serif;font-size:12px;border:none;cursor:pointer;letter-spacing:0.05em;">CANCEL</button>
            <button id="timeSelConfirm" style="flex:1;padding:12px;background:#262626;color:#57FF86;font-family:'Open Sans',sans-serif;font-size:12px;border:none;cursor:pointer;letter-spacing:0.05em;">SET ›</button>
        </div>
    </div>
</div>

<script type="text/javascript">


function BtoMB(beats){
        var mbM = Math.floor(beats/ts_numerator);
        var mbB = beats - (mbM*ts_numerator);
        return (mbM + "." + mbB)
        }

var transitionsButton = document.getElementById("transitionsButton");
if(transitionsButton){
    doTransitionButton();
    transitionsButton.onclick = function(){
        transitions ^= 1;
        doTransitionButton();
        }
    }

function doTransitionButton(){
    if(transitions==1){
        transitionsButton.childNodes[3].setAttributeNS(null, "visibility", "visible");
        transitionsButton.childNodes[7].setAttributeNS(null, "visibility", "hidden");
        for (var i=0; i<hereCss.cssRules.length; i++){
            if(hereCss.cssRules[i].selectorText=="#optionsBar"){
                hereCss.deleteRule(i);
                hereCss.insertRule("#optionsBar {overflow-y: hidden;-webkit-transition: all 0.2s ease-out;-o-transition: all 0.2s ease-out;transition: all 0.2s ease-out;}",i);
                }
            }
        }
    else{
        transitionsButton.childNodes[3].setAttributeNS(null, "visibility", "hidden");
        transitionsButton.childNodes[7].setAttributeNS(null, "visibility", "visible");
        for (var i=0; i<hereCss.cssRules.length; i++){
            if(hereCss.cssRules[i].selectorText=="#optionsBar"){
                hereCss.deleteRule(i);
                hereCss.insertRule("#optionsBar {overflow-y: hidden;}",i);
                }
            }
        }
    }

var jogger = document.getElementById("jogger");
var joggerWidth = jogger.getBoundingClientRect()["width"];
jogger.addEventListener("mousedown", joggerHandler, false);
jogger.addEventListener('touchstart', function(event){
    if (event.touches.length > 0) joggerHandler(event);
    event.preventDefault();
    }, false);

function joggerHandler(){
    var jOffsetX = 0;
    var mouseOnJogger = true;
    var jTimer = setInterval(joggerCounter, 100)

    if (event.targetTouches != undefined) {startX = event.targetTouches[0].pageX}
        else {startX = event.pageX}

    jogger.addEventListener('touchend', function(event){joggerUp();event.preventDefault();}, false);
    jogger.addEventListener("mouseup", joggerUp, false);

    function joggerUp(){
        mouseOnJogger = false;
        var joggerAggExp = Math.exp(Math.abs(joggerAgg)) * Math.sign(joggerAgg);

        if(statusPosition[1]=="Measures.Beats"){
            var joggerAggExpB = (Math.floor(Math.exp(Math.abs(joggerAgg)))) * Math.sign(joggerAgg);
            var sPs = statusPosition[0].split(".")
            var sumB = (parseInt(sPs[1]) + joggerAggExpB);
            var mbM = Math.floor(sumB/ts_numerator)
            var mbB = sumB - (mbM*ts_numerator);
            var newM = mbM + parseInt(sPs[0]);
                if(snapState==1) wwr_req("SET/POS_STR/" + newM + "." + mbB + ".00");
                else wwr_req("SET/POS_STR/" + newM + "." + mbB + "." + sPs[2]);
            }
        else{
            pos = parseFloat(playPosSeconds);
            wwr_req("SET/POS/" + (pos + joggerAggExp));
            }
        clearInterval(jTimer);
        joggerRotate(0);
        setTimeout(function(){ joggerAgg = "0"; }, 500);
        }

    jogger.addEventListener("mouseleave", joggerLeave, false);

    function joggerLeave(){
        mouseOnJogger = false;
        clearInterval(jTimer);
        joggerRotate(0);
        joggerAgg = "0";
        }

    jogger.addEventListener("touchmove", function(event){joggerMove();event.preventDefault();}, false);
    jogger.addEventListener("mousemove", joggerMove, false);

    function joggerMove(){
        if(mouseOnJogger == true){

            if (event.changedTouches != undefined) { //we're doing touch stuff
                jOffsetX = (event.changedTouches[0].pageX - startX) / joggerWidth;
                }
            else {jOffsetX = (event.pageX - startX) / joggerWidth;}
            if(jOffsetX>0.5)(jOffsetX=0.5);
            if(jOffsetX<-0.5)(jOffsetX=-0.5);
            joggerRotate(jOffsetX*90);
            jMOffsetX = jOffsetX;
            }
        else{
            joggerRotate(0);
            }
        }

    function joggerCounter(){
        if(mouseOnJogger == true){
        joggerAgg = parseFloat(joggerAgg) + jMOffsetX;
            }
        }
    }

function joggerRotate(angle){
    var wheel = document.getElementById("wheel");
    var wheelClipRect = document.getElementById("clip_rect");
    var wheelAngle = "rotate(" + angle + " 159 181)";
    var clipAngle = "rotate(" + (-1 * angle) + " 159 181)";
    wheel.setAttributeNS(null, "transform", wheelAngle);
    wheelClipRect.setAttributeNS(null, "transform", clipAngle);
    }

var requestAnimationFrame = window.requestAnimationFrame ||
                window.mozRequestAnimationFrame ||
                window.webkitRequestAnimationFrame ||
                window.msRequestAnimationFrame;

function easeInOutCubic(t, b, c, d) {
    if ((t/=d/2) < 1){
    return c/2*t*t*t + b;}
    else{return c/2*((t-=2)*t*t + 2) + b;}
    };


// --- Marker delete on double-tap ---


["marker1","marker2","marker3"].forEach(function(id) {
    var el = document.getElementById(id);
    if (!el) return;
    el.setAttribute("pointer-events", "all");
    el.style.cursor = "pointer";

    el.addEventListener("click", function(e) {
        e.stopPropagation();

        var numberEl = document.getElementById(id + "Number");
        var bgEl     = document.getElementById(id + "Bg");
        var pending  = markerDeletePending[id];

        if (pending) {
            // Second tap — delete
            clearTimeout(pending.timer);
            delete markerDeletePending[id];
            var warpBack = playPosSeconds;
            wwr_req("SET/POS/" + pending.markerTime);
            wwr_req(40613);
            wwr_req("SET/POS/" + warpBack);
            delete warpBack;
            numberEl.textContent = pending.markerIdx;
            bgEl.setAttributeNS(null, "fill", pending.origFill);
            numberEl.setAttributeNS(null, "fill", lumaOffset(pending.origFill));
            return;
        }

        // First tap — read idx from current text
        var idx = parseInt(numberEl.textContent);
        if (!idx || isNaN(idx)) return;

        // Look up time from g_markers
        var markerTime = null;
        for (var i = 0; i < g_markers.length; i++) {
            if (parseInt(g_markers[i][2]) == idx) {
                markerTime = g_markers[i][3];
                break;
            }
        }
        if (markerTime === null) return;

        var origFill = bgEl.getAttribute("fill") || "#1a1a1a";
        bgEl.setAttributeNS(null, "fill", "#8B0000");
        numberEl.textContent = "✕";
        numberEl.setAttributeNS(null, "fill", "#FF4444");

        markerDeletePending[id] = {
            markerIdx:  idx,
            markerTime: markerTime,
            origFill:   origFill,
            timer: setTimeout(function() {
                delete markerDeletePending[id];
                numberEl.textContent = idx;
                bgEl.setAttributeNS(null, "fill", origFill);
                numberEl.setAttributeNS(null, "fill", lumaOffset(origFill));
            }, 2500)
        };
    });
});


// --- Pan knob drag ---
var panDragging = false, panDragTrackId = null, panDragStartX = 0, panDragStartVal = 0;

document.addEventListener("mousemove", panDragMove);
document.addEventListener("touchmove", panDragMove, {passive: false});
document.addEventListener("mouseup",   panDragEnd);
document.addEventListener("touchend",  panDragEnd);

function panKnobConnect(row2Content, trackIdx) {
    var knob = row2Content.firstChild.getElementsByClassName("panKnob")[0];
    if (!knob || knob.dataset.panConnected) return;
    knob.dataset.panConnected = "1";

    function startPan(e) {
        e.preventDefault();
        e.stopPropagation();
        panDragging = true;
        panDragTrackId = trackIdx;
        panDragStartY = e.touches ? e.touches[0].pageY : e.pageY;
        panDragStartVal = trackPanAr[trackIdx] || 0;
    }
    knob.addEventListener("mousedown",  startPan);
    knob.addEventListener("touchstart", startPan, {passive: false});
}

function panDragMove(e) {
    if (!panDragging) return;
    var pageY = e.touches ? e.touches[0].pageY : e.pageY;
    var delta = (pageY - panDragStartY) / 160; // 80px = full sweep
    var newPan = Math.max(-1, Math.min(1, panDragStartVal - delta));

    // Update knob visually
    var trackRow2 = document.getElementsByClassName("trackRow2")[panDragTrackId];
    if (trackRow2 && trackRow2.firstChild) {
        var panLine = trackRow2.firstChild.getElementsByClassName("panLine")[0];
        if (panLine) panLine.setAttribute("transform", "rotate(" + (newPan * 135) + " 20 18)");
        var panLabel = trackRow2.firstChild.getElementsByClassName("panLabel")[0];
        if (panLabel) {
            var pct = Math.round(newPan * 100);
            panLabel.textContent = pct === 0 ? "PAN" : (pct > 0 ? "R" + pct : "L" + Math.abs(pct));
        }
    }
    trackPanAr[panDragTrackId] = newPan;
    wwr_req("SET/TRACK/" + panDragTrackId + "/PAN/" + newPan);
    if (e.cancelable) e.preventDefault();
}

function panDragEnd() {
    if (!panDragging) return;
    panDragging = false;
    // Reset label to PAN after brief delay
    var tid = panDragTrackId;
    setTimeout(function() {
        var trackRow2 = document.getElementsByClassName("trackRow2")[tid];
        if (trackRow2 && trackRow2.firstChild) {
            var panLabel = trackRow2.firstChild.getElementsByClassName("panLabel")[0];
            if (panLabel) panLabel.textContent = "PAN";
        }
    }, 1500);
    panDragTrackId = null;
}

// --- Track delete (double-tap confirm) ---
var trackDeletePending = {};

function trackDeleteConnect(row2Content, trackIdx) {
    var btn = row2Content.firstChild.getElementsByClassName("trackDeleteBtn")[0];
    if (!btn || btn.dataset.deleteConnected) return;
    btn.dataset.deleteConnected = "1";

    btn.addEventListener("click", function(e) {
        e.stopPropagation();
        var normal  = btn.getElementsByClassName("trackDeleteNormal")[0];
        var confirm = btn.getElementsByClassName("trackDeleteConfirm")[0];
        var pending = trackDeletePending[trackIdx];

        if (pending) {
            clearTimeout(pending.timer);
            delete trackDeletePending[trackIdx];
            normal.setAttribute("visibility",  "visible");
            confirm.setAttribute("visibility", "hidden");
            wwr_req(40297);
            wwr_req("SET/TRACK/" + trackIdx + "/SEL/1");
            wwr_req(40005);
            var lastTrack = document.getElementById("track" + nTrack);
            if (lastTrack) lastTrack.parentNode.removeChild(lastTrack);
            return;
        }

        // First tap — show confirm state
        normal.setAttribute("visibility",  "hidden");
        confirm.setAttribute("visibility", "visible");

        trackDeletePending[trackIdx] = {
            timer: setTimeout(function() {
                delete trackDeletePending[trackIdx];
                normal.setAttribute("visibility",  "visible");
                confirm.setAttribute("visibility", "hidden");
            }, 2500)
        };
    });
}

function removeAllTracks() {
    document.getElementById("tracks").innerHTML = "";
    trackNamesAr = [];
    trackNumbersAr = [];
    trackColoursAr = [];
    trackFlagsAr = [];
    faderConAr = [];
    trackPanAr = [];
    trackPeakAr = [];
    trackPeakLive = [];
    trackSendCntAr = [];
    trackRcvCntAr = [];
    trackHwOutCntAr = [];
    trackSendHwCntAr = [];
    recarmCountAr = [];
    recCycleInProgress = [];
}

function wwr_req_then_poll(maxAttempts) {
    return new Promise(function(resolve, reject) {
        maxAttempts = maxAttempts || 20;
        var attempts = 0;
        var done = false;

        function listener(results) {
            if (done) return;
            var ar = results.split("\n");
            for (var i = 0; i < ar.length; i++) {
                var tok = ar[i].split("\t");
                if (tok[0] == "EXTSTATE" && tok[1] == "Fanciest" && tok[2] == "ProjectList" && tok[3] && tok[3] != "") {
                    done = true;
                    clearInterval(interval);
                    wwr_listeners = wwr_listeners.filter(function(f) { return f !== listener; });
                    resolve(tok[3]);
                    return;
                }
            }
        };

        wwr_listeners.push(listener);
        wwr_req("_RS8cadb1ca78c92dde23e1cfb80251615246076640");

        var interval = setInterval(function() {
            if (done) { clearInterval(interval); return; }
            attempts++;
            wwr_req("GET/EXTSTATE/Fanciest/ProjectList");
            if (attempts >= maxAttempts) {
                clearInterval(interval);
                if (!done) {
                    done = true;
                    wwr_listeners = wwr_listeners.filter(function(f) { return f !== listener; });
                    reject("timed out");
                }
            }
        }, 200);
    });
}

var selectedProject = null;

function openProjectModal(projects) {
    var modal = document.getElementById("projectModal");
    var list  = document.getElementById("projectList");
    selectedProject = null;

    // populate list
    list.innerHTML = "";
    // rest of item creation
    projects.filter(function(p) { return p.trim() !== ""; }).forEach(function(name) {
        var item = document.createElement("div");
        name = name.trim();
        item.textContent = name;
        item.style.cssText = "padding:12px 16px;color:#9DA5A5;font-family:'Open Sans',sans-serif;font-size:13px;border-bottom:1px solid #333;cursor:pointer;";
        item.addEventListener("click", function() {
            // deselect all
            list.querySelectorAll("div").forEach(function(el) {
                el.style.background = "transparent";
                el.style.color = "#9DA5A5";
            });
            // select this
            item.style.background = "#1a1a1a";
            item.style.color = "#57FF86";
            selectedProject = name;
        });
        list.appendChild(item);
    });

    modal.style.display = "flex";
}

function closeProjectModal() {
    document.getElementById("projectModal").style.display = "none";
    selectedProject = null;
    updateProjectName();
    updateTempo();
}

document.getElementById("projectModalBackdrop").addEventListener("click", closeProjectModal);

document.getElementById("btnNewProject").addEventListener("click", function() {
    removeAllTracks();
    closeProjectModal();
    wwr_req("_RS1957801e5ef25efacf651d6ae726903c4d7db3ea"); // new project action
});

document.getElementById("btnConfirmLoad").addEventListener("click", function(e) {
    e.stopPropagation();
    //console.log("selectedProject:", JSON.stringify(selectedProject));
    if (!selectedProject) return;
    removeAllTracks();
    wwr_req("SET/EXTSTATE/Fanciest/ProjectLoad/" + selectedProject + ";_RSdd85326a069bbb93f19234630cc46ee78740de5f");// load project
    console.log("load", selectedProject);
    closeProjectModal();
});


document.getElementById("btnOpen").addEventListener("click", async function(e) {
    e.stopPropagation();
    try {
        var result = await wwr_req_then_poll();
        openProjectModal(result.split("\\n"));
    } catch(e) {
        console.log("failed:", e);
    }
});

document.getElementById("btnSave").addEventListener("click", function(e) {
    e.stopPropagation();
    el = document.getElementById("projectNameDisplay");
    if (el) {
        //console.log(el);
        promptName = el.textContent.replace(".RPP","");
    } else {
        promptName = "New Project";
    }
    saveName = prompt("Save project with title:",promptName);
    if (!saveName) return;
    wwr_req("SET/EXTSTATE/Fanciest/ProjectSave/" + saveName + ';_RS93e9c007de60cfbaa87114d130a0b719ee8bdea2');// save project
    //wwr_req("");//
    console.log("save", saveName);
    updateProjectName();
});


var tempoEditMode = null; // "bpm", "num", or "den"
var currentTempo = 120;
updateTempo();

function openTempoModal() {
    updateTempo();
    document.getElementById("tempoDisplay").textContent = Number(currentTempo).toFixed(3);
    document.getElementById("timeSigNum").textContent = ts_numerator;
    document.getElementById("timeSigDen").textContent = ts_denominator;
    document.getElementById("tempoEditArea").style.display = "none";
    tempoEditMode = null;
    document.getElementById("tempoModal").style.display = "flex";
}

function closeTempoModal() {
    document.getElementById("tempoModal").style.display = "none";
    document.getElementById("tempoEditArea").style.display = "none";
    tempoEditMode = null;
}

//~ function openTempoEdit(mode) {
    //~ tempoEditMode = mode;
    //~ var input = document.getElementById("tempoEditInput");
    //~ var label = document.getElementById("tempoEditLabel");
    //~ var area  = document.getElementById("tempoEditArea");

    //~ if (mode === "bpm") {
        //~ label.textContent = "BPM";
        //~ input.type = "number";
        //~ input.min = "20";
        //~ input.max = "960";
        //~ input.step = "0.001";
        //~ input.value = currentTempo.toFixed(3);
    //~ } else if (mode === "num") {
        //~ label.textContent = "BEATS PER BAR";
        //~ input.type = "number";
        //~ input.min = "1";
        //~ input.max = "32";
        //~ input.step = "1";
        //~ input.value = ts_numerator;
    //~ } else if (mode === "den") {
        //~ label.textContent = "BEAT VALUE";
        //~ input.type = "number";
        //~ input.min = "1";
        //~ input.max = "32";
        //~ input.step = "1";
        //~ input.value = ts_denominator;
    //~ }

    //~ area.style.display = "block";
    //~ setTimeout(function() { input.focus(); input.select(); }, 50);
//~ }

function confirmTempoEdit() {
    //~ var input = document.getElementById("tempoEditInput");
    //~ var val = parseFloat(input.value);
    //~ if (isNaN(val)) { closeTempoEdit(); return; }

    //~ if (tempoEditMode === "bpm") {
        //~ val = Math.min(960, Math.max(20, val));
        //~ currentTempo = val;
        //~ wwr_req("SET/TEMPO/" + val);
        //~ document.getElementById("tempoDisplay").textContent = val.toFixed(3);
    //~ } else if (tempoEditMode === "num") {
        //~ val = Math.min(32, Math.max(1, Math.round(val)));
        //~ wwr_req("SET/TIMESIG/" + val + "/" + ts_denominator);
        //~ document.getElementById("timeSigNum").textContent = val;
    //~ } else if (tempoEditMode === "den") {
        //~ val = Math.min(32, Math.max(1, Math.round(val)));
        //~ wwr_req("SET/TIMESIG/" + ts_numerator + "/" + val);
        //~ document.getElementById("timeSigDen").textContent = val;
    //~ }

    closeTempoEdit();
}

function closeTempoEdit() {
    document.getElementById("tempoEditArea").style.display = "none";
    tempoEditMode = null;
}



// wire up backdrop and close
document.getElementById("tempoModalBackdrop").addEventListener("click", closeTempoModal);
document.getElementById("tempoModalClose").addEventListener("click", closeTempoModal);

// wire up tappable rows
//~ document.getElementById("tempoDisplay").addEventListener("click", function() { openTempoEdit("bpm"); });
document.getElementById("tempoDisplay").addEventListener("click", function() {
    var result = prompt("BPM:", Number(currentTempo).toFixed(3));
    if (!result) return;
    var val = Math.min(960, Math.max(20, parseFloat(result)));
    if (isNaN(val)) return;
    currentTempo = val;
    wwr_req("SET/EXTSTATE/Fanciest/TempoSet/" + val + ";_RS64f1ac6929d9b4a3c9a2f04bec48dc96cc3c2467");
    document.getElementById("tempoDisplay").textContent = val.toFixed(3);
});
//~ document.getElementById("timeSigDisplay").addEventListener("click", function(e) {
    //~ // figure out if they tapped num or den based on Y position
    //~ var rect = document.getElementById("timeSigDisplay").getBoundingClientRect();
    //~ var mid  = rect.top + rect.height / 2;
    //~ openTempoEdit(e.clientY < mid ? "num" : "den");
//~ });

document.getElementById("timeSigDisplay").addEventListener("click", function(e) {
    e.stopPropagation();
    var result = prompt("Time signature:", ts_numerator + "/" + ts_denominator);
    if (!result) return;
    var parts = result.split("/");
    if (parts.length !== 2) return;
    var num = Math.min(32, Math.max(1, parseInt(parts[0])));
    var den = Math.min(32, Math.max(1, parseInt(parts[1])));
    if (isNaN(num) || isNaN(den)) return;
    wwr_req("SET/EXTSTATE/Fanciest/TimeSigSet/" + num + ":" + den + ";_RS64f1ac6929d9b4a3c9a2f04bec48dc96cc3c2467");
    document.getElementById("timeSigNum").textContent = num;
    document.getElementById("timeSigDen").textContent = den;
});

// edit area buttons
document.getElementById("tempoEditCancel").addEventListener("click", closeTempoEdit);
document.getElementById("tempoEditConfirm").addEventListener("click", confirmTempoEdit);
document.getElementById("tempoEditInput").addEventListener("keydown", function(e) {
    if (e.key === "Enter")  confirmTempoEdit();
    if (e.key === "Escape") closeTempoEdit();
});

function requestRecCycle(idx, maxAttempts) {
    return new Promise(function(resolve, reject) {
        maxAttempts = maxAttempts || 40;
        var attempts = 0;
        var done = false;

        function listener(results) {
            if (done) return;
            var ar = results.split("\n");
            for (var i = 0; i < ar.length; i++) {
                var tok = ar[i].split("\t");
                if (tok[0] == "EXTSTATE" && tok[1] == "Fanciest" && tok[2] == "RecCycleSuccess" && tok[3] && tok[3] != "") {
                    done = true;
                    clearInterval(interval);
                    wwr_listeners = wwr_listeners.filter(function(f) { return f !== listener; });
                    resolve(tok[3]);
                    return;
                }
            }
        }

        wwr_listeners.push(listener);
        wwr_req("SET/EXTSTATE/Fanciest/TrackRecordCycle/" + idx + ";_RSc3da218412ee1db98a7e4b76deaf8677bcdc4d05");

        var interval = setInterval(function() {
            if (done) { clearInterval(interval); return; }
            attempts++;
            wwr_req("GET/EXTSTATE/Fanciest/RecCycleSuccess");
            if (attempts >= maxAttempts) {
                clearInterval(interval);
                if (!done) {
                    done = true;
                    wwr_listeners = wwr_listeners.filter(function(f) { return f !== listener; });
                    reject("timed out");
                }
            }
        }, 100);
    });
}

var timeSelFrom = null, timeSelTo = null;

function openTimeSelModal() {
    timeSelFrom = null;
    timeSelTo = null;

    function buildMarkerButtons(containerId, onSelect) {
        var container = document.getElementById(containerId);
        container.innerHTML = "";

        // HOME
        var homeBtn = document.createElement("div");
        homeBtn.style.cssText = "padding:6px 10px;border-radius:3px;cursor:pointer;font-size:12px;border:1px solid #404040;background:#1a1a1a;color:#9DA5A5;";
        homeBtn.textContent = "H HOME";
        homeBtn.addEventListener("click", function() {
            container.querySelectorAll("div").forEach(function(b) {
                b.style.background = "#1a1a1a";
                b.style.color = "#9DA5A5";
                b.style.borderColor = "#404040";
            });
            homeBtn.style.background = "#404040";
            homeBtn.style.color = "#A8A8A8";
            homeBtn.style.borderColor = "#808080";
            onSelect("home");
        });
        container.appendChild(homeBtn);

        // regular markers
        g_markers.forEach(function(m) {
            var idx  = m[2];
            var name = m[1] || ("M" + idx);
            var col  = "#" + (m[4]|0x1000000).toString(16).substr(-6);
            var btn  = document.createElement("div");
            btn.style.cssText = "padding:6px 10px;border-radius:3px;cursor:pointer;font-size:12px;border:1px solid #404040;background:#1a1a1a;color:#9DA5A5;";
            btn.textContent = idx + (name ? " " + name : "");
            btn.addEventListener("click", function() {
                container.querySelectorAll("div").forEach(function(b) {
                    b.style.background = "#1a1a1a";
                    b.style.color = "#9DA5A5";
                    b.style.borderColor = "#404040";
                });
                btn.style.background = col;
                btn.style.color = lumaOffset(col);
                btn.style.borderColor = col;
                onSelect(idx);
            });
            container.appendChild(btn);
        });

        // END — use project length
        var endBtn = document.createElement("div");
        endBtn.style.cssText = "padding:6px 10px;border-radius:3px;cursor:pointer;font-size:12px;border:1px solid #404040;background:#1a1a1a;color:#9DA5A5;";
        endBtn.textContent = "E END";
        endBtn.addEventListener("click", function() {
            container.querySelectorAll("div").forEach(function(b) {
                b.style.background = "#1a1a1a";
                b.style.color = "#9DA5A5";
                b.style.borderColor = "#404040";
            });
            endBtn.style.background = "#404040";
            endBtn.style.color = "#A8A8A8";
            endBtn.style.borderColor = "#808080";
            onSelect("end"); // REAPER clamps to project end
        });
        container.appendChild(endBtn);
    }

    buildMarkerButtons("timeSelFromList", function(t) { timeSelFrom = t; });
    buildMarkerButtons("timeSelToList",   function(t) { timeSelTo   = t; });

    document.getElementById("timeSelModal").style.display = "flex";
}

function closeTimeSelModal() {
    document.getElementById("timeSelModal").style.display = "none";
    timeSelFrom = null;
    timeSelTo   = null;
    updateProjectName();
}

document.getElementById("timeSelBackdrop").addEventListener("click", closeTimeSelModal);
document.getElementById("timeSelCancel").addEventListener("click", closeTimeSelModal);
document.getElementById("timeSelConfirm").addEventListener("click", function(e) {
    e.stopPropagation();
    if (timeSelFrom === null || timeSelTo === null) return;
    wwr_req("SET/EXTSTATE/Fanciest/MarkerLoop/" + timeSelFrom + ":" + timeSelTo);
    wwr_req("_RS254ca0027c86edd7b7e9541466a2cc48906f6079");
    closeTimeSelModal();
});


</script>
</body>
</html>
