module JusticeGovSk
  module Request
    class SpecialHearingList < JusticeGovSk::Request::HearingList
      def url
        @url ||= "#{super}/Stranky/Pojednavania/PojednavanieSpecZoznam.aspx"
      end
    end
  end
end