// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$('#check_all').on("click", function() {
    var checked = this.checked;
    $('input[name="reports[]"]:enabled').map(function() {
        $(this).prop("checked", checked);
    })
});

$('.generate_reports').on("click", function() {
    var report_types = $('input[name="reports[]"]:checked').map(function() {
      return $(this).val();
    }).get();
    if (report_types.length) {
        $(this).prop("disabled", true);
        $('#check_all').prop("disabled", true);
        var ingest_id = $('#id').val();
        var count = 0;
        var total = report_types.length;
        report_types.forEach(function(report_type) {
            $.ajax({
                url: "/qa/reporting/create",
                data: {id: ingest_id, report_type: report_type},
                success: function() {
                    count++;
                    $("." + report_type + "_link").html("Generating.");
                    if (count == total) {
                        window.location.replace("/qa/reporting/provider?id=" + ingest_id);
                    }
                }
            });
        });
    }
});

if ($('.running').length) {
    setInterval(function() {
        var ingest_id = $('#id').val();
        $.ajax({
            url: "/qa/reporting/provider",
            data: {id: ingest_id}
        });
    }, 5000);
}