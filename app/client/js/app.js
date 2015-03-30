
// handy exists function
jQuery.fn.exists = function(){return jQuery(this).length>0;}

$(document).ready(jQueryReady);



//### main script called on "page ready" event ###
//Startup Step 3
function jQueryReady() {

	$("a.makebutton").button();
	$("input.makebutton").button();

	submitDatabaseForm();

	addLoading();

}

function addLoading() {
    $("body").prepend("<div id='loading' style='display:none;'><img src='/images/spinner.gif'/></div>");
}

function showLoading() {

	$("div#loading").dialog({
		resizable : false,
		closeOnEscape : false,
		height:85,
		width: 70,
		minWidth:70,
		modal: true,
		open: function(event, ui) {
			$(".ui-dialog-titlebar").hide();
		    $("a.ui-dialog-titlebar-close").remove();
		  }
	});
}


function submitDatabaseForm() {
	var select = $("#database");
	select.change(function(){
		showLoading();
		$("#databaseform").submit();
	});
}


function uploadFileDialog(){
	$('div#fileUploadDialog').dialog({
		title: "Upload Service Metrics File",
		resizable : false,
		closeOnEscape : false,
	    width: 450,
		modal: true,
		open: function(event, ui) {
		    $("a.ui-dialog-titlebar-close").remove();
		  }
	});
}

function uploadFile() {
	$('div#fileUploadDialog').dialog('close');
	$('#serviceFileUploadForm').submit();
}


function closeUploadFileDialog(){
	$('div#fileUploadDialog').dialog('close');
}

function submitSearch(page) {
 	$("#pagenumber").val(page);
 	$("#searchForm").submit();
}

function submitFacetSearch(facet) {
 	$("#selectedfacet").val(facet);
 	$("#searchForm").submit();
}
function clearcache(){
	$("#selectedfacet").val("");
	$("#pagenumber").val(1);
	return true;
}
function clearFacet(facet) {
 	$("#selectedfacet").val("");
 	$("#searchForm").submit();
}

function togglequery(){
	$("#qrydetails").toggle();
}

function loop(j, k, f)
{
	for (; j <= k; j++) {
		f(j);
	}
}