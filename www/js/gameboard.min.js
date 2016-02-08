$(function() {
      (new Image).src = 'images/gameboard/DNLD.png';
      $('.download')
	  .mouseover(function () {
			 $this = $(this);
			 if (!$this.data('image')) $this.data('image', $this.attr('src'));
			 $this.attr('src','images/gameboard/DNLD.png');
		     })
	  .mouseout(function () {
			 $this = $(this);
			 $this.attr('src', $this.data('image'));
		    });
  });
