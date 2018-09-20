import { AUTOCOMPLETE_DEFAULTS, SimpleMDE, Turbolinks } from 'shared'

$(document).on('turbolinks:load', function() {
  $(".stick_in_parent").stick_in_parent();

  addDatepickerBehaviors();

  $('#site_visibility_level_active').on('click', function(){
    $('#site_username').val('');
    $('#site_password').val('');
  });

  $('a[data-disabled]').on('click', function(e){
    e.preventDefault();
  });

  var $autocomplete = $('[data-autocomplete]');

  var searchOptions = {
    serviceUrl: $autocomplete.data('autocomplete'),
    onSelect: function(suggestion) {
      Turbolinks.visit(suggestion.data.url);
    }
  };

  $autocomplete.devbridgeAutocomplete($.extend({}, AUTOCOMPLETE_DEFAULTS, searchOptions));

  $('[data-wysiwyg]').each(function(){
    var $el = $(this);
    var simplemde = new SimpleMDE({
      element: $el[0],
      autofocus: true,
      forceSync: true,
      spellChecker: false,
      renderingConfig: {
        singleLineBreaks: false
      },
      status: false
    });

    $el.data({editor: simplemde});
    simplemde.codemirror.on("change", function(){
      var id = "#" + $el.attr('id').replace('_source', '');
      $(id).val(simplemde.markdown(simplemde.value()))
    });
  });
});

function addDatepickerBehaviors() {
  if ($('.air-datepicker').length == 1) {
    initializePageWithOnlyOneDatepicker();
  } else if($('.air-datepicker').length){
    var $fromDatePickers = $('.air-datepicker:even');
    var $toDatePickers   = $('.air-datepicker:odd');

    $toDatePickers.each(function(index, toDatePicker) {

      // Check if properties were informed before set defaults
      const toDatePickerDEFAULTS = {
        autoClose: ($(toDatePicker).data('autoclose') === undefined)
          ? true
          : ($(toDatePicker).data('autoclose')),
        startDate: ($(toDatePicker).data('startdate') === undefined)
          ? new Date()
          : new Date($(toDatePicker).data('startdate'))
      }

      // Datepicker end time
      $(toDatePicker).datepicker({
        autoClose: toDatePickerDEFAULTS.autoClose,
        startDate: toDatePickerDEFAULTS.startDate,
        onSelect: function onSelect(a, selectedDate, instance) {
          $(instance.el).trigger("datepicker-change");

          // Updates first datepicker if end_date is earlier
          if (selectedDate < $(fromDatePicker).data('datepicker').lastSelectedDate) {
            selectedDate.setHours(selectedDate.getHours() - 1)
            setDateOnBindedDatepicker(selectedDate, fromDatePicker)
          }
        }
      });

      // Datepicker start time
      var fromDatePicker = $fromDatePickers[index];

      // Check if properties were informed before set defaults
      const fromDatePickerDEFAULTS = {
        autoClose: ($(fromDatePicker).data('autoclose') === undefined)
          ? true
          : ($(fromDatePicker).data('autoclose')),
        minutesStep: ($(fromDatePicker).data('minutesstep') === undefined)
          ? 5
          : ($(fromDatePicker).data('minutesstep')),
        startDate: ($(fromDatePicker).data('startdate') === undefined)
          ? new Date()
          : new Date($(fromDatePicker).data('startdate')),
      }

      if($(fromDatePicker).data('range') === undefined) {
        $(fromDatePicker).datepicker({
          autoClose: fromDatePickerDEFAULTS.autoClose,
          minutesStep: fromDatePickerDEFAULTS.minutesStep,
          startDate: fromDatePickerDEFAULTS.startDate,
          onSelect: function onSelect(_, selectedDate, instance) {
            $(instance.el).trigger("datepicker-change");

            // data-bind=true links fromDatePicker to toDatePicker
            // on fromDatePicker selection, updates toDatePicker +1h
            if ($(instance.el).data('bind')) {
              selectedDate.setHours(selectedDate.getHours() + 1)
            }

            if (selectedDate > $(toDatePicker).data('datepicker').lastSelectedDate) {
              setDateOnBindedDatepicker(selectedDate, toDatePicker)
            }
          }
        });

        var date = new Date($(fromDatePicker).data('startdate'));

        $(fromDatePicker).data('datepicker').selectDate(date);
        if($(toDatePicker).length){
          date = new Date($(toDatePicker).data('startdate'));
          $(toDatePicker).data('datepicker').selectDate(date);
        }
      } else {
        $(fromDatePicker).datepicker({
          autoClose: fromDatePickerDEFAULTS.autoClose,
          onSelect: function onSelect(_, selectedDate, instance) {
            $(instance.el).trigger("datepicker-change");
          }
        });
      }

      index++;
    });
  }
}

function initializePageWithOnlyOneDatepicker() {
  const $datepicker = $('.air-datepicker')

  // Check if properties were informed before set defaults
  const datePickerDEFAULTS = {
    autoClose: ($datepicker.data('autoclose') === undefined) ? true : ($datepicker.data('autoclose')),
    startDate: ($datepicker.data('startdate') === undefined) ? new Date() : new Date($datepicker.data('startdate'))
  }

  $('.air-datepicker').datepicker({
    autoClose: datePickerDEFAULTS.autoClose,
    startDate: datePickerDEFAULTS.startDate,
    onSelect: function onSelect(_, selectedDate, instance) {
      $(instance.el).trigger("datepicker-change");
    }
  });
}

function setDateOnBindedDatepicker(date, datepicker) {
  if($(datepicker).length) {
    $(datepicker).data('datepicker').selectDate(date);
  }
}

export { addDatepickerBehaviors }
