$(document).ready(function (){
    jQuery("#request_token").bind("click", function(e){
        e.preventDefault();
        data = { password: $("#password").val(), authorize: 'true' };
        var target = $("#request_token_form");
        jQuery.ajax({
            url: '../api_keys/'+$("#api-key-id").val(),
            dataType: 'JSON',
            type: 'PUT',
            data: data,
            beforeSend: function(){
                target.hide();
                $("#request-token-spinner").show();
            },
            complete: function(){
                $("#request-token-spinner").hide();
            },
            success: function(data){
                $("#step2-intro").hide();
                $("#request-token-message").html(data.message).show();
                $(".token").html(data.token);
                $("#api-ready").show();
            },
            error: function(request){
                var response_message = jQuery.parseJSON(request.responseText)
                var message = (request.status == 403) ? response_message.message : "An unknown error occurred. Support has been contacted.";
                $("#step2-intro").hide();
                $("#request-token-message").html(message).show();
                if (request.status == 403){ $("#request_token_form").show()  }
            }
        });
    });
    
    $("#request_key").bind("click", function(e){
        e.preventDefault();
        var target = $("#request_key");
        jQuery.ajax({
            url: '../api_keys/',
            dataType: 'JSON',
            type: 'POST',
            beforeSend: function(){
                target.hide();
                $("#request-spinner").show();
            },
            complete: function(){
                $("#request-spinner").hide();
            },
            success: function(data){
                $("#step1-intro").hide();
                $("#request-message").html(data.message).show();
                $("#app-id").html(data.application.uid);
                $("#api-key-id").val(data.apiKeyId);
                $("#app-secret").html(data.application.secret);
                $("#app-info").show();
                $("#step-two").show(); 
            },
            error: function(request){
                var message = (request.status == 403) ? request.responseText : "An unknown error occurred. Support has been contacted.";
                $("#request-message").html(message).show();
                if (request.status == 403){ $("#request_key").show()  }
            }
      
        });
    });
});
