module ApplicationHelper

  # set these values per view within each controller
  def meta_tag(tag, text)
    content_for :"meta_#{tag}", text
  end

  def yield_meta_tag(tag, default_text='')
    content_for(:"meta_#{tag}") || default_text
  end

  def title(page_title)
    content_for :title, page_title
  end

  def heading(page_heading)
    content_for :heading, page_heading
  end

  #removed padding for day, month, and hour
  #added non-breaking space before PM
  def date_format(utc_date)
    utc_date.strftime("%-m/%-d/%y %-I:%M\u00A0%p")
  end

  # convert true / false into Yes / No
  def humanize_boolean(input)
    input ||= ''
    case input.to_s.downcase
    when 't', 'true'
      'Yes'
    else
      'No'
    end
  end

  # to convert true / false into a css class success / danger
  def css_for_boolean(input)
    if input
      'success'
    else
      'danger'
    end
  end
end
