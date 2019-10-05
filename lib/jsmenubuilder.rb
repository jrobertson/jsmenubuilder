#!/usr/bin/env ruby

# file: jsmenubuilder.rb

require 'rexle'
require 'rexle-builder'

class JsMenuBuilder
  using ColouredText

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

FULL_PAGE_TABS_CSS =<<EOF
/* Set height of body and the document to 100% to enable "full page tabs" */
body, html {
  height: 100%;
  margin: 0;
  font-family: Arial;
}

/* Style tab links */
.tablink {
  background-color: #555;
  color: white;
  float: left;
  border: none;
  outline: none;
  cursor: pointer;
  padding: 14px 16px;
  font-size: 17px;
  width: 25%;
}

button.active {
  background-color: #c55;
}

.tablink:hover {
  background-color: #777;
}



/* Style the tab content (and add height:100% for full page content) */
.tabcontent {
  color: #000;
  display: none;
  padding: 100px 20px;
  height: 100%;
}

EOF

ACCORDION_CSS = %q(
.accordion {
  background-color: #eee;
  color: #444;
  cursor: pointer;
  padding: 18px;
  width: 100%;
  border: none;
  text-align: left;
  outline: none;
  font-size: 15px;
  transition: 0.4s;
}

.active, .accordion:hover {
  background-color: #ccc;
}

.accordion:after {
  content: '\002B';
  color: #777;
  font-weight: bold;
  float: right;
  margin-left: 5px;
}

.active:after {
  content: "\2212";
}

.panel {
  padding: 0 18px;
  background-color: white;
  max-height: 0;
  overflow: hidden;
  transition: max-height 0.2s ease-out;
}
)

FULL_PAGE_TABS_JS =<<EOF
function openPage(pageName,elmnt) {
  var i, tabcontent;
  tabcontent = document.getElementsByClassName("tabcontent");
  for (i = 0; i < tabcontent.length; i++) {
    tabcontent[i].style.display = "none";
  }

  // Get all elements with class="tablink" and remove the class "active"
  tablink = document.getElementsByClassName("tablink");
  for (i = 0; i < tablink.length; i++) {
    tablink[i].className = tablink[i].className.replace(" active", "");
  }


  document.getElementById(pageName).style.display = "block";
  elmnt.className += " active";
}

// Get the element with id="defaultOpen" and click on it
document.getElementById("defaultOpen").click();
EOF

ACCORDION_JS =<<EOF
var acc = document.getElementsByClassName("accordion");
var i;

for (i = 0; i < acc.length; i++) {
  acc[i].addEventListener("click", function() {
    this.classList.toggle("active");
    var panel = this.nextElementSibling;
    e = panel.children[0];

    if (panel.style.maxHeight){
      panel.style.maxHeight = null;
                              
      if (e) {
                              
        let event = new Event("dblclick");
        e.dispatchEvent(event);                              

      }
    }                                               
    else {
      panel.style.maxHeight = panel.scrollHeight + "px";
      if (e)
        e.click()            
    } 
  });
}

EOF


  attr_reader :html, :css, :js

  def initialize(unknown=nil, options={})
    
    @debug = options[:debug]
    puts 'options: ' + options.inspect if @debug    
    
    if unknown.is_a? Symbol
      type = unknown.to_sym
      
    elsif unknown.is_a? String then
      
      s, _ = RXFHelper.read unknown
      if s =~ /^<tags/ then
        options = parse_xml(s)
        type = options.keys.first
      else
        type = unknown.to_sym
      end

    elsif unknown.is_a? Hash
      options = unknown
    end    

    @types = %i(tabs full_page_tabs accordion)
    
    build(type, options) if type

  end
  
  def import(xml)
    
    puts 'inside import'.info if @debug
    doc = Rexle.new(xml)
    type = doc.root.attributes[:mode]
    
    type = if type == 'fullpage' then
    'full_page_tabs'
    elsif type.nil?
      doc.root.name unless type
    end
    
    tabs = doc.root.xpath('tab').inject({}) do |r, tab|
      r.merge(tab.attributes[:title] => tab.children.join.strip)
    end
    
    e = doc.root.element('tab[@mode="active"]')
    
    default_tab = if e then
      title = e.attributes[:title]
      (tabs.keys.index(title) + 1).to_s
    else
      '1'
    end

    h = { active: default_tab, tabs: tabs}
    build(type, h)
    self
    
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
  
  def to_xml()
    @xml
  end
  
  
  private
  
  def build(type, options)
    
    puts 'inside build'.info if @debug
    puts "type: %s\noptions: %s".debug % [type, options] if @debug
    
    type = :full_page_tabs if type.to_sym == :fullpage
    
    return unless @types.include? type.to_sym
    
    doc = method(type.to_sym).call(options)
    puts 'doc: ' + doc.inspect if @debug
    
    @html = doc.xml(pretty: true, declaration: false)\
      .gsub(/<\/div>/,'\0' + "\n").strip.lines[1..-2]\
      .map {|x| x.sub(/^  /,'') }.join
    
    @css = Object.const_get self.class.to_s + '::' + type.to_s.upcase + '_CSS'
    @js = Object.const_get self.class.to_s + '::' + type.to_s.upcase + '_JS'    
    
    @xml = build_xml(type.to_sym, options)
    
  end
  
  def build_h(doc)
    
    puts 'inside build_h'.info if @debug
    
    h = doc.root.xpath('tag').inject({}) do |r,e|
      r.merge(e.attributes[:title] => e.children.join.strip)
    end
    
    puts ('build_h: ' + h.inspect).debug if @debug
    
    {doc.root.attributes[:mode].to_s.to_sym => h}
    
  end  
  
  def build_xml(type, opt={})

    puts 'inside build_xml'.info if @debug
    puts 'type: ' + type.inspect if @debug
    
    options = if type.to_s =~ /tabs\b/ then
      {active: '1'}.merge(opt)
    else
      opt
    end    

    entries = if options[:headings] then
      headings = options[:headings]
      headings.zip(headings.map {|heading| ['h3', {}, heading]}).to_h
    else
      options[type.to_sym]
    end
    
    puts 'entries: ' + entries.inspect if @debug

    a = RexleBuilder.build do |xml|
      xml.tags({mode: type}) do 
        entries.each do |heading, content|
          xml.tag({title: heading}, content )
        end
      end
    end

    doc = Rexle.new(a)
 
    if options[:active] then
      e = doc.root.element("tag[#{options[:active]}]")
      e.attributes[:mode] = 'active' if e
    end

    return doc.xml(pretty: true)

  end  
  
  def parse_xml(s)
    doc = Rexle.new(s)
    build_h(doc)
  end

  def tabs(opt={})

    options = {active: '1'}.merge(opt)

    tabs = if options[:headings] then
      headings = options[:headings]
      headings.zip(headings.map {|heading| ['h3', {}, heading]}).to_h
    else
      options[:tabs]
    end

    a = RexleBuilder.build do |xml|
      xml.html do 

        xml.comment!(' Tab links ')
        xml.div(class: 'tab' ) do
          tabs.keys.each do |heading|
            xml.button({class:'tablinks', 
                        onclick: %Q(openTab(event, "#{heading}"))}, heading.to_s)
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

    return doc

  end
  
  def full_page_tabs(opt={})

    options = {active: '1'}.merge(opt)

    tabs = if options[:headings] then
      headings = options[:headings]
      headings.zip(headings.map {|heading| ['h3', {}, heading]}).to_h
    else
      options[:tabs]
    end                                                     

    a = RexleBuilder.build do |xml|
      xml.html do 

        tabs.keys.each do |heading|
          xml.button({class:'tablink', 
                      onclick: %Q(openPage("#{heading}", this))}, heading.to_s)
        end

        tabs.each do |heading, content|
          puts 'content: ' + content.inspect
          xml.div({id: heading, class: 'tabcontent'}, content )
        end
      end
    end

    doc = Rexle.new(a)
 
    e = doc.root.element("button[#{options[:active]}]")
    e.attributes[:id] = 'defaultOpen' if e

    return doc

    
  end

  def accordion(opt={})

    panels = opt[:accordion]
    debug = @debug

    a = RexleBuilder.build do |xml|
      xml.html do 

        panels.each do |heading, inner_html|
          puts 'inner_html: ' + inner_html.inspect if debug
          xml.button({class:'accordion'}, heading.to_s)
          xml.div({class:'panel'}, inner_html)
        end

      end
    end

    doc = Rexle.new(a)
    puts 'doc: ' + doc.xml.inspect if @debug
    return doc
    
  end
  

end
