# Introducing the JsMenuBuilder gem

## Usage

    require 'jsmenubuilder'


    tabs = {
      'London' => '<h3>London</h3><p>Good morning</p>', 
      'Paris' => '<p>Bonjour</p>', 
      'Tokyo' => '<p>Konnichiwa</p>'
    }

    jmb = JsMenuBuilder.new(:tabs, tabs: tabs, active: '2')
    puts jmb.html
    puts jmb.to_webpage
    File.write '/tmp/foo.html', jmb.to_webpage
    `firefox /tmp/foo.html &`

The above example generates a web page containing 3 tabs which are clickable and changes the content without reloading the page.

## Resource

* jsmenubuilder https://rubygems.org/gems/jsmenubuilder

jsmenubulder menu tabstab html js css template
