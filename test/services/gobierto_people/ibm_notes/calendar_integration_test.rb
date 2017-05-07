require 'test_helper'
require 'support/calendar_integration_helpers'

module GobiertoPeople
  module IbmNotes
    class CalendarIntegrationTest < ActiveSupport::TestCase

      include ::CalendarIntegrationHelpers

      def richard
        @richard ||= gobierto_people_people(:richard)
      end

      def tamara
        @tamara ||= gobierto_people_people(:tamara)
      end

      def setup
        super
        outdated_ibm_notes_event_gobierto_event.save!
        ibm_notes_event_gobierto_event.save!
      end

      def utc_time(date)
        d = Time.parse(date)
        Time.utc(d.year, d.month, d.day, d.hour, d.min, d.sec)
      end

      def rst_to_utc(date)
        ActiveSupport::TimeZone['Madrid'].parse(date).utc
      end

      def create_ibm_notes_event(params = {})
        ::IbmNotes::PersonEvent.new(richard, {
          'id'       => params[:id] || 'Ibm Notes event ID',
          'summary'  => params[:summary] || 'Ibm Notes event summary',
          'location' => params.has_key?(:location) ? params[:location] : 'Ibm Notes event location',
          'start'    => { 'date' => '2017-04-11', 'time' => '10:00:00', 'utc' => true },
          'end'      => { 'date' => '2017-04-11', 'time' => '11:00:00', 'utc' => true }
        })
      end

      def new_ibm_notes_event
        @new_ibm_notes_event ||= create_ibm_notes_event(
          id: 'Ibm Notes new event ID',
          summary: 'Ibm Notes new event summary',
          location: 'Ibm Notes new event location',
        )
      end

      def outdated_ibm_notes_event
        @outdated_ibm_notes_event ||= create_ibm_notes_event(
          id: 'Ibm Notes outdated event ID',
          summary: 'Ibm Notes outdated event title - THIS HAS CHANGED',
          location: 'Ibm Notes outdated event location - THIS HAS CHANGED'
        )
      end

      def ibm_notes_event_gobierto_event
        @ibm_notes_event_gobierto_event ||= GobiertoPeople::PersonEvent.new(
          external_id: 'Ibm Notes event ID',
          title: 'Ibm Notes event title',
          starts_at: utc_time("2017-04-11 10:00:00"),
          ends_at:   utc_time("2017-04-11 11:00:00"),
          state: GobiertoPeople::PersonEvent.states['published'],
          person: richard
        )
      end

      def outdated_ibm_notes_event_gobierto_event
        @outdated_ibm_notes_event_gobierto_event ||= GobiertoPeople::PersonEvent.new(
          external_id: 'Ibm Notes outdated event ID',
          title: 'Ibm Notes outdated event title',
          starts_at: utc_time("2017-04-11 10:00:00"),
          ends_at:   utc_time("2017-04-11 11:00:00"),
          state: GobiertoPeople::PersonEvent.states['published'],
          person: richard
        )
      end

      def test_sync_events_v9
        activate_calendar_integration(sites(:madrid))
        set_calendar_endpoint(richard, 'https://host.wadus.com/mail/foo.nsf/api/calendar/events')

        VCR.use_cassette('ibm_notes/person_events_collection_v9', decode_compressed_response: true) do
          CalendarIntegration.sync_person_events(richard)
        end

        non_recurrent_events       = richard.events.where("external_id ~* ?", "-Lotus_Notes_Generated$")
        recurrent_events_instances = richard.events.where("external_id ~* ?", "-Lotus_Notes_Generated/\\d{8}T\\d{6}Z$")

        assert_equal 2, non_recurrent_events.count
        assert_equal 1, recurrent_events_instances.count

        assert_equal "Buscar alcaldessa al seu despatx i Sortida cap a l'acte Gran Via Corts Catalanes, 400", non_recurrent_events.first.title
        assert_equal rst_to_utc("2017-05-04 18:45:00"), non_recurrent_events.first.starts_at

        assert_equal "Lliurament Premis Rac", non_recurrent_events.second.title
        assert_equal rst_to_utc("2017-05-04 19:30:00"), non_recurrent_events.second.starts_at

        assert_equal "CAEM", recurrent_events_instances.first.title
        assert_equal rst_to_utc("2017-05-05 09:00:00"), recurrent_events_instances.first.starts_at
      end

      def test_sync_events_updates_event_attributes
        activate_calendar_integration(sites(:madrid))
        set_calendar_endpoint(richard, 'https://host.wadus.com/mail/foo.nsf/api/calendar/events')

        VCR.use_cassette('ibm_notes/person_events_collection_v9', decode_compressed_response: true) do
          CalendarIntegration.sync_person_events(richard)
        end

        # Change arbitrary data, and check it gets  updated accordingly after the
        # next synchronization

        non_recurrent_event = richard.events.find_by(external_id: 'BD5EA243F9F715AAC1258116003ED56C-Lotus_Notes_Generated')
        non_recurrent_event.title = 'Old non recurrent event title'
        non_recurrent_event.starts_at = utc_time("2017-05-05 10:00:00")
        non_recurrent_event.save!

        recurrent_event_instance = richard.events.find_by(external_id: 'D2E5B40E6AAEAED4C125808E0035A6A0-Lotus_Notes_Generated/20170503T073000Z')
        recurrent_event_instance.title = 'Old recurrent event instance title'
        recurrent_event_instance.locations.first.update_attributes!(name: 'Old location')
        recurrent_event_instance.save!

        VCR.use_cassette('ibm_notes/person_events_collection_v9', decode_compressed_response: true) do
          CalendarIntegration.sync_person_events(richard)
        end

        assert "Buscar alcaldessa al seu despatx i Sortida cap a l'acte Gran Via Corts Catalanes, 400", non_recurrent_event.title
        assert rst_to_utc("2017-05-04 16:45:00"), non_recurrent_event.starts_at

        assert 'CAEM', recurrent_event_instance.title
        assert 'Sala de juntes 1a. planta Ajuntament', recurrent_event_instance.locations.first.name
      end

      def test_sync_events_removes_deleted_event_attributes
        activate_calendar_integration(sites(:madrid))
        set_calendar_endpoint(richard, 'https://host.wadus.com/mail/foo.nsf/api/calendar/events')

        VCR.use_cassette('ibm_notes/person_events_collection_v9', decode_compressed_response: true) do
          CalendarIntegration.sync_person_events(richard)
        end

        # Add new data to events, and check it is removed after sync
        event = richard.events.find_by(external_id: 'BD5EA243F9F715AAC1258116003ED56C-Lotus_Notes_Generated')
        GobiertoPeople::PersonEventLocation.create!(person_event: event, name: "I'll be deleted")

        VCR.use_cassette('ibm_notes/person_events_collection_v9', decode_compressed_response: true) do
          CalendarIntegration.sync_person_events(richard)
        end

        event.reload
        assert event.locations.empty?
      end

      # Se piden eventos en el intervalo [1,3], 1 y 3 son recurrentes y son el mismo, el 2 es uno no recurrente
      # De las 9 instancias del evento recurrente, la que tiene recurrenceId=20170407T113000Z (la segunda) da 404
      def test_sync_events_v8
        activate_calendar_integration(sites(:madrid))
        set_calendar_endpoint(tamara, 'https://host.wadus.com/mail/bar.nsf/api/calendar/events')

        VCR.use_cassette('ibm_notes/person_events_collection_v8', decode_compressed_response: true) do
          CalendarIntegration.sync_person_events(tamara)
        end

        non_recurrent_events       = tamara.events.where("external_id ~* ?", "-Lotus_Notes_Generated$")
        recurrent_events_instances = tamara.events.where("external_id ~* ?", "-Lotus_Notes_Generated/\\d{8}T\\d{6}Z$").order(:external_id)

        assert_equal 1, non_recurrent_events.count
        assert_equal 8, recurrent_events_instances.count

        assert_equal "rom", non_recurrent_events.first.title
        assert_equal 'CD1B539AEB0D44D7C1258110003BB81E-Lotus_Notes_Generated', non_recurrent_events.first.external_id
        assert_equal rst_to_utc('2017-05-05 16:00:00'), non_recurrent_events.first.starts_at

        assert_equal "Coordinació Política Igualtat + dinar", recurrent_events_instances.first.title
        assert_equal 'EE3C4CEA30187126C12580A300468AEF-Lotus_Notes_Generated/20170303T110000Z', recurrent_events_instances.first.external_id
        assert_equal rst_to_utc('2017-03-03 12:00:00'), recurrent_events_instances.first.starts_at

        assert_equal "Coordinació Política Igualtat + dinar", recurrent_events_instances.second.title
        assert_equal 'EE3C4CEA30187126C12580A300468AEF-Lotus_Notes_Generated/20170505T100000Z', recurrent_events_instances.second.external_id
        assert_equal rst_to_utc('2017-05-05 12:00:00'), recurrent_events_instances.second.starts_at
      end

      def test_sync_events_marks_unreceived_events_as_pending
        activate_calendar_integration(sites(:madrid))
        set_calendar_endpoint(richard, 'https://host.wadus.com/mail/foo.nsf/api/calendar/events')

        VCR.use_cassette('ibm_notes/person_events_collection_v9', decode_compressed_response: true) do
          CalendarIntegration.sync_person_events(richard)
        end

        non_recurrent_events = richard.events.where("external_id ~* ?", "-Lotus_Notes_Generated$")

        assert_equal 2, non_recurrent_events.count

        assert non_recurrent_events.first.active?
        assert non_recurrent_events.second.active?

        VCR.use_cassette('ibm_notes/person_events_collection_v9_mark_as_pending', decode_compressed_response: true) do
          CalendarIntegration.sync_person_events(richard)
        end

        non_recurrent_events = richard.events.where("external_id ~* ?", "-Lotus_Notes_Generated$").order(:external_id)

        assert_equal 2, non_recurrent_events.count

        refute non_recurrent_events.first.active?
        assert non_recurrent_events.second.active?
      end

      def test_sync_event_creates_new_event_with_location
        refute GobiertoPeople::PersonEvent.exists?(external_id: new_ibm_notes_event.id)

        CalendarIntegration.sync_event(new_ibm_notes_event)

        assert GobiertoPeople::PersonEvent.exists?(external_id: new_ibm_notes_event.id)

        gobierto_event = GobiertoPeople::PersonEvent.find_by(external_id: new_ibm_notes_event.id)

        assert_equal new_ibm_notes_event.title, gobierto_event.title
        assert_equal richard, gobierto_event.person

        assert_equal 'Ibm Notes new event location', gobierto_event.locations.first.name
      end

      def test_sync_event_updates_existing_event
        CalendarIntegration.sync_event(outdated_ibm_notes_event)

        updated_gobierto_event = GobiertoPeople::PersonEvent.find_by(external_id: outdated_ibm_notes_event.id)

        assert updated_gobierto_event.published?
        assert_equal 'Ibm Notes outdated event title - THIS HAS CHANGED', updated_gobierto_event.title
      end

      def test_sync_event_doesnt_create_duplicated_events
        CalendarIntegration.sync_event(outdated_ibm_notes_event)

        assert_no_difference 'GobiertoPeople::PersonEvent.count' do
          CalendarIntegration.sync_event(outdated_ibm_notes_event)
        end
      end

      def test_sync_event_creates_updates_and_removes_location_for_existing_gobierto_event
        ibm_notes_event = create_ibm_notes_event(location: nil)
        gobierto_event = GobiertoPeople::PersonEvent.find_by!(external_id: ibm_notes_event.id)

        CalendarIntegration.sync_event(ibm_notes_event)

        gobierto_event.reload
        assert gobierto_event.locations.empty?

        ibm_notes_event.location = 'Location name added afterwards'

        CalendarIntegration.sync_event(ibm_notes_event)
        gobierto_event.reload

        assert 'Location name added afterwards', gobierto_event.locations.first.name

        ibm_notes_event.location = 'Location name updated afterwards'

        CalendarIntegration.sync_event(ibm_notes_event)
        gobierto_event.reload

        assert 'Location name updated afterwards', gobierto_event.locations.first.name

        ibm_notes_event.location = nil

        CalendarIntegration.sync_event(ibm_notes_event)
        gobierto_event.reload

        assert gobierto_event.locations.empty?
      end

    end
  end
end
