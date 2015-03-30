$( document ).ready(function() {
    console.log( "ready!" );
    var xmlNotPretty = $("#xml-code").text();
    var xmlPretty = vkbeautify.xml(xmlNotPretty);
    $("#xml-code").text(xmlPretty);
});