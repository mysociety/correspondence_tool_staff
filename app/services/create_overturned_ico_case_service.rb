class CreateOverturnedICOCaseService

  attr_reader :original_ico_appeal, :overturned_ico_case

  def initialize(ico_appeal_id)
    @original_ico_appeal = Case::Base.find(ico_appeal_id)
    @error = false
  end

  def error?
    @error
  end

  def success?
    !@error
  end

  def call
    overturned_klass = case @original_ico_appeal.type
                        when 'Case::ICO::FOI'
                          Case::OverturnedICO::FOI
                         when 'Case::ICO::SAR'
                           Case::OverturnedICO::SAR
                         else
                           @original_ico_appeal.errors.add(:base, 'Invalid ICO appeal case type')
                           @error = true
                       end
    if success?
      original_case                                 = @original_ico_appeal.original_case
      @overturned_ico_case                          = overturned_klass.new
      # @overturned_ic_case.subject                  = original_case.subject
      @overturned_ico_case.original_ico_appeal_id   = @original_ico_appeal.id
      @overturned_ico_case.original_case_id         = original_case.id
      @overturned_ico_case.set_reply_method if original_case.sar?

      original_case.related_cases.each do |related_case|
        add_relatd_case(@overturned_ico_case, related_case)
      end
      @overturned_ico_case.save!
    end
  end


  private

  def add_related_case(kase, related_kase)
    kase_link = LinkedCase.new(
        linked_case_number: related_kase.to_s&.strip
    )

    #Create the links
    kase.related_case_links << kase_link
  end


end
