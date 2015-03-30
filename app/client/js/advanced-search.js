
var availableTags = [
  "docType:",
  "inDir:",
  "AND",
  "OR",
  "NEAR",
  "NOT_IN",
  "LT",
  "LE",
  "GT",
  "GE",
  "NE",
  "person"
];

var curText = "";
var prevWord = false;
var curPos;

function split( val ) {
    return val.split( /\b\s*/ );
  }

function extractLast( term ) {
  return split( term ).pop();
}

function setupAutocomplete() {
  $( "#search" )
  // don't navigate away from the field on tab when selecting an item
  .bind( "keydown", function( event ) {
    if ( event.keyCode === $.ui.keyCode.TAB &&
        $( this ).autocomplete( "instance" ).menu.active ) {
      event.preventDefault();
    }
  })
  .autocomplete({
    minLength: 1,
    multi: true,
    //autoFocus: true,
    source: function( request, response ) {
      // delegate back to autocomplete, but extract the last term
      response( $.ui.autocomplete.filter(
        availableTags, extractLast( request.term ) ) );
    },
    response: function( event, ui ) {
      curPos = this.selectionStart;
      console.log("text entered at "+ curPos);
      
      if (this.value.length > curPos) prevWord = true;
      
    },
    focus: function() {
      // prevent value inserted on focus
      return false;
    },
    select: function( event, ui ) {
      var terms = split( this.value );
      console.log("event: " + event.result);
      
      if (!prevWord) {
        // remove the current input
        terms.pop();
        // add the selected item
        terms.push( ui.item.value );
        // add placeholder to get the comma-and-space at the end
        terms.push( "" );
        this.value = terms.join( " " );
        return false;
      }
      
    },
  open: function( event, ui ) {
      var input = $( event.target ),
          widget = input.autocomplete( "widget" ),
          style = $.extend( input.css( [
              "font",
              "border-left",
              "padding-left"
          ] ), {
              position: "absolute",
              visibility: "hidden",
              "padding-right": 0,
              "border-right": 0,
              "white-space": "pre"
          } ),
          div = $( "<div/>" ),
          pos = {
              my: "left top",
              collision: "none"
          },
          offset = -7; // magic number to align the first letter
                       // in the text field with the first letter
                       // of suggestions
                       // depends on how you style the autocomplete box

      widget.css( "width", "" );

      div
          .text( input.val().replace( /\S*$/, "" ) )
          .css( style )
          .insertAfter( input );
      offset = Math.min(
          Math.max( offset + div.width(), 0 ),
          input.width() - widget.width()
      );
      div.remove();

      pos.at = "left+" + offset + " bottom";
      input.autocomplete( "option", "position", pos );

      widget.position( $.extend( { of: input }, pos ) );
    }
  });  
}

setTimeout(setupAutocomplete,500);