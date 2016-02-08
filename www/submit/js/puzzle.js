$(function(){
  $('input.placeholder').each(function() {
    if($(this).val().length == 0)
      $(this)
        .addClass('dimmed_text')
        .val($(this).attr('defaultvalue'));
  });

  $('input.placeholder')
    .focus(function(){ 
        if($(this).val() == $(this).attr('defaultvalue'))
          $(this)
            .val('')
            .removeClass('dimmed_text');
      })
    .blur(function(){
        if($(this).val().length == 0)
          $(this)
            .addClass('dimmed_text')
            .val($(this).attr('defaultvalue'));
      });

  $('form').submit(function(){
      $(this).find('input.placeholder').each(function() {
          if($(this).val() == $(this).attr('defaultvalue'))
	      $(this).val('');
      });
      return true;
  });

  if ($('.conf_image').length) {
      $(window).load(function() {
			 setTimeout(function() {
					$('.conf_image')
					    .fadeOut('slow', function() {
							 $('.clear_after_conf')
							     .val('').blur();
						     });
				    }, 2000);
		     });
  }
}); 
