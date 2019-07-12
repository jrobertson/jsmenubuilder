#!/usr/bin/env ruby

# file: jsmenubuilder.rb

require 'rexle'
require 'rexle-builder'

class JsMenuBuilder

TABS_CSS =<<EOF
/* Style the tab */
.tab {
  overflow: hidden;
  border: 1px solid #ccc;
  background-color: #f1f1f1;
}

/* Style the buttons that are used to open the tab content */
.tab button {
  background-color: inherit;
  float: left;
  border: none;
  outline: none;
  cursor: pointer;
  padding: 14px 16px;
  transition: 0.3s;
}

/* Change background color of buttons on hover */
.tab button:hover {
  background-color: #ddd;
}

/* Create an active/current tablink class */
.tab button.active {
  background-color: #ccc;
}

/* Style the tab content */
.tabcontent {
  display: none;
  padding: 6px 12px;
  border: 1px solid #ccc;
  border-top: none;
}
EOF

TABS_JS =<<EOF
function openTab(evt, tabName) {
  // Declare all variables
  var i, tabcontent, tablinks;

  // Get all elements with class="tabcontent" and hide them
  tabcontent = document.getElementsByClassName("tabcontent");
  for (i = 0; i < tabcontent.length; i++) {
    tabcontent[i].style.display = "none";
  }

  // Get all elements with class="tablinks" and remove the class "active"
  tablinks = document.getElementsByClassName("tablinks");
  for (i = 0; i < tablinks.length; i++) {
    tablinks[i].className = tablinks[i].className.replace(" active", "");
  }

  // Show the current tab, and add an "active" class to the button that opened the tab
  document.getElementById(tabName).style.display = "block";
  evt.currentTarget.className += " active";
}

// Get the element with id="defaultOpen" and click on it
document.getElementById("defaultOpen").click();
EOF



  attr_reader :html, :css, :js

  def initialize(type, options={})

    @type = type
    types = %i(tabs)
    method(type.to_sym).call(options) if types.include? type

  end
  
  def to_css()
    @css
  end
  
  def to_html()
    @html
  end
  
  def to_js()
    @js
  end
  
  def to_webpage()

    a = RexleBuilder.build do |xml|
      xml.html do 
        xml.head do
          xml.meta name: "viewport", content: \
              "width=device-width, initial-scale=1"
          xml.style "\nbody {font-family: Arial;}\n\n" + @css
        end
        xml.body
      end
    end

    doc = Rexle.new(a)
    e = Rexle.new("<html>%s</html>" % @html).root
    
    e.children.each {|child| doc.root.element('body').add child }
    
    doc.root.element('body').add \
        Rexle::Element.new('script').add_text "\n" + 
        @js.gsub(/^ +\/\/[^\n]+\n/,'')
    
    "<!DOCTYPE html>\n" + doc.xml(pretty: true, declaration: false)\
        .gsub(/<\/div>/,'\0' + "\n").gsub(/\n *<!--[^>]+>/,'')
    
  end
  
  private

  def tabs(opt={})

    options = {active: '1'}.merge(opt)

    tabs = if options[:headings] then
      headings = options[:headings]
      headings.zip(headings.map {|heading| ['h3', {}, heading]}).to_h
    else
      options[:tabs]
    end
                             
                         
    ## build the HTML

    a = RexleBuilder.build do |xml|
      xml.html do 

        xml.comment!(' Tab links ')
        xml.div(class: 'tab' ) do
          tabs.keys.each do |heading|
            xml.button({class:'tablinks', 
                        onclick: %Q(openTab(event, "#{heading}"))}, heading)
          end
        end

        xml.comment!(' Tab content ')

        tabs.each do |heading, content|
          puts 'content: ' + content.inspect
          xml.div({id: heading, class: 'tabcontent'}, content )
        end
      end
    end

    doc = Rexle.new(a)
 
    e = doc.root.element("div/button[#{options[:active]}]")
    e.attributes[:id] = 'defaultOpen' if e

    @html = doc.xml(pretty: true, declaration: false)\
      .gsub(/<\/div>/,'\0' + "\n").strip.lines[1..-2]\
      .map {|x| x.sub(/^  /,'') }.join
    
    @css = Object.const_get 'JsMenuBuilder::' + @type.to_s.upcase + '_CSS'
    @js = Object.const_get 'JsMenuBuilder::' + @type.to_s.upcase + '_JS'
    
  end

end
