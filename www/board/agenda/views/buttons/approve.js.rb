#
# Approve/Unapprove a report
#
class Approve < React
  def initialize
    @disabled = false
    @request = 'approve'
  end

  # render a single button
  def render
    _button.btn.btn_primary @request, onClick: self.click, disabled: @disabled
  end

  # set request and button text on initial load
  def componentWillMount()
    self.componentWillReceiveProps()
  end

  # set request (and button text) depending on whether or not the
  # not this items was previously approved
  def componentWillReceiveProps()
    if Pending.approved.include? @@item.attach
      @request = 'unapprove'
    elsif Pending.unapproved.include? @@item.attach
      @request = 'approve'
    elsif @@item.approved and @@item.approved.include? Server.initials
      @request = 'unapprove'
    else
      @request = 'approve'
    end
  end

  # when button is clicked, send request
  def click(event)
    data = {
      agenda: Agenda.file,
      initials: Server.initials,
      attach: @@item.attach,
      request: @request
    }

    @disabled = true
    post 'approve', data do |pending|
      @disabled = false
      Pending.load pending
    end
  end
end
