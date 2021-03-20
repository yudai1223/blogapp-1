# Haml (HTML Abstraction Markup Language)

Haml is a markup language that's used to cleanly and simply describe the HTML of
any web document, without the use of inline code. Haml functions as a
replacement for inline page templating systems such as PHP, ERB, and ASP.
However, Haml avoids the need for explicitly coding HTML into the template,
because it is actually an abstract description of the HTML, with some code to
generate dynamic content.

## Features

* Whitespace active
* Well-formatted markup
* DRY
* Follows CSS conventions
* Integrates Ruby code
* Implements Rails templates with the .haml extension

## Using Haml

Haml can be used in three ways:

* as a command-line tool,
* as a plugin for Ruby on Rails,
* and as a standalone Ruby module.

The first step for all of these is to install the Haml gem:

    gem install haml

To run Haml from the command line, just use

    haml input.haml output.html

Use `haml --help` for full documentation.

To use Haml with Rails, add the following line to the Gemfile:

    gem "haml"

Once it's installed, all view files with the `".html.haml"` extension will be
compiled using Haml.

You can access instance variables in Haml templates the same way you do in ERB
templates. Helper methods are also available in Haml templates. For example:

    # file: app/controllers/movies_controller.rb

    class MoviesController < ApplicationController
      def index
        @title = "Teen Wolf"
      end
    end

    -# file: app/views/movies/index.html.haml

    #content
     .title
       %h1= @title
       = link_to 'Home', home_url

may be compiled to:

    <div id='content'>
      <div class='title'>
        <h1>Teen Wolf</h1>
        <a href='/'>Home</a>
      </div>
    </div>

### Rails XSS Protection

Haml supports Rails' XSS protection scheme, which was introduced in Rails 2.3.5+
and is enabled by default in 3.0.0+. If it's enabled, Haml's
{Haml::Options#escape_html `:escape_html`} option is set to `true` by default -
like in ERB, all strings printed to a Haml template are escaped by default. Also
like ERB, strings marked as HTML safe are not escaped. Haml also has [its own
syntax for printing a raw string to the template](#unescaping_html).

If the `:escape_html` option is set to false when XSS protection is enabled,
Haml doesn't escape Ruby strings by default. However, if a string marked
HTML-safe is passed to [Haml's escaping syntax](#escaping_html), it won't be
escaped.

Finally, all the {Haml::Helpers Haml helpers} that return strings that are known
to be HTML safe are marked as such. In addition, string input is escaped unless
it's HTML safe.

### Ruby Module

Haml can also be used completely separately from Rails and ActionView. To do
this, install the gem with RubyGems:

    gem install haml

You can then use it by including the "haml" gem in Ruby code, and using
{Haml::Engine} like so:

    engine = Haml::Engine.new("%p Haml code!")
    engine.render #=> "<p>Haml code!</p>\n"

### Options

Haml understands various configuration options that affect its performance and
output.

In Rails, options can be set by setting the {Haml::Template#options Haml::Template.options}
hash in an initializer:

    # config/initializers/haml.rb
    Haml::Template.options[:format] = :html5

Outside Rails, you can set them by configuring them globally in
Haml::Options.defaults:

    Haml::Options.defaults[:format] = :html5

In sinatra specifically, you can set them in global config with:
```ruby
set :haml, { escape_html: true }
```

Finally, you can also set them by passing an options hash to
{Haml::Engine#initialize}. For the complete list of available options, please
see {Haml::Options}.

### Encodings

Haml supports the same sorts of
encoding-declaration comments that Ruby does. Although both Ruby and Haml
support several different styles, the easiest it just to add `-# coding:
encoding-name` at the beginning of the Haml template (it must come before all
other lines). This will tell Haml that the template is encoded using the named
encoding.

By default, the HTML generated by Haml has the same encoding as the Haml
template. However, if `Encoding.default_internal` is set, Haml will attempt to
use that instead. In addition, the {Haml::Options#encoding `:encoding` option}
can be used to specify an output encoding manually.

Note that, like Ruby, Haml does not support templates encoded in UTF-16 or
UTF-32, since these encodings are not compatible with ASCII. It is possible to
use these as the output encoding, though.

## Plain Text

A substantial portion of any HTML document is its content, which is plain old
text. Any Haml line that's not interpreted as something else is taken to be
plain text, and passed through unmodified. For example:

    %gee
      %whiz
        Wow this is cool!

is compiled to:

    <gee>
      <whiz>
        Wow this is cool!
      </whiz>
    </gee>

Note that HTML tags are passed through unmodified as well. If you have some HTML
you don't want to convert to Haml, or you're converting a file line-by-line, you
can just include it as-is. For example:

    %p
      <div id="blah">Blah!</div>

is compiled to:

    <p>
      <div id="blah">Blah!</div>
    </p>

### Escaping: `\`

The backslash character escapes the first character of a line, allowing use of
otherwise interpreted characters as plain text. For example:

    %title
      = @title
      \= @title

is compiled to:

    <title>
      MyPage
      = @title
    </title>

## HTML Elements

### Element Name: `%`

The percent character is placed at the beginning of a line. It's followed
immediately by the name of an element, then optionally by modifiers (see below),
a space, and text to be rendered inside the element. It creates an element in
the form of `<element></element>`. For example:

    %one
      %two
        %three Hey there

is compiled to:

    <one>
      <two>
        <three>Hey there</three>
      </two>
    </one>

Any string is a valid element name; Haml will automatically generate opening and
closing tags for any element.

### Attributes: `{}` or `()` {#attributes}

Brackets represent a Ruby hash that is used for specifying the attributes of an
element. It is literally evaluated as a Ruby hash, so logic will work in it and
local variables may be used. Quote characters within the attribute will be
replaced by appropriate escape sequences. The hash is placed after the tag is
defined. For example:

    %html{:xmlns => "http://www.w3.org/1999/xhtml", "xml:lang" => "en", :lang => "en"}

is compiled to:

    <html xmlns='http://www.w3.org/1999/xhtml' xml:lang='en' lang='en'></html>

Attribute hashes can also be stretched out over multiple lines to accommodate
many attributes.

    %script{
      "type": text/javascript",
      "src": javascripts/script_#{2 + 7}",
      "data": {
        "controller": "reporter",
      },
    }

is compiled to:

    <script src='javascripts/script_9' type='text/javascript' data-controller='reporter'></script>

#### `:class` and `:id` Attributes {#class-and-id-attributes}

The `:class` and `:id` attributes can also be specified as a Ruby array whose
elements will be joined together. A `:class` array is joined with `" "` and an
`:id` array is joined with `"_"`. For example:

    %div{:id => [@item.type, @item.number], :class => [@item.type, @item.urgency]}

is equivalent to:

    %div{:id => "#{@item.type}_#{@item.number}", :class => "#{@item.type} #{@item.urgency}"}

The array will first be flattened and any elements that do not test as true will
be removed. The remaining elements will be converted to strings. For example:

    %div{:class => [@item.type, @item == @sortcol && [:sort, @sortdir]] } Contents

could render as any of:

    <div class="numeric sort ascending">Contents</div>
    <div class="numeric">Contents</div>
    <div class="sort descending">Contents</div>
    <div>Contents</div>

depending on whether `@item.type` is `"numeric"` or `nil`, whether `@item == @sortcol`,
and whether `@sortdir` is `"ascending"` or `"descending"`.

If a single value is specified and it evaluates to false it is ignored;
otherwise it gets converted to a string. For example:

    .item{:class => @item.is_empty? && "empty"}

could render as either of:

    class="item"
    class="item empty"

#### HTML-style Attributes: `()`

Haml also supports a terser, less Ruby-specific attribute syntax based on HTML's
attributes. These are used with parentheses instead of brackets, like so:

    %html(xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en")

Ruby variables can be used by omitting the quotes. Local variables or instance
variables can be used. For example:

    %a(title=@title href=href) Stuff

This is the same as:

    %a{:title => @title, :href => href} Stuff

Because there are no commas separating attributes, though, more complicated
expressions aren't allowed. For those you'll have to use the `{}` syntax. You
can, however, use both syntaxes together:

    %a(title=@title){:href => @link.href} Stuff

You can also use `#{}` interpolation to insert complicated expressions in a
HTML-style attribute:

    %span(class="widget_#{@widget.number}")

HTML-style attributes can be stretched across multiple lines just like
hash-style attributes:

    %script(type="text/javascript"
            src="javascripts/script_#{2 + 7}")

#### Ruby 1.9-style Hashes

Haml also supports Ruby's new hash syntax:

    %a{title: @title, href: href} Stuff

#### Attribute Methods

A Ruby method call that returns a hash can be substituted for the hash contents.
For example, {Haml::Helpers} defines the following method:

    def html_attrs(lang = 'en-US')
      {:xmlns => "http://www.w3.org/1999/xhtml", 'xml:lang' => lang, :lang => lang}
    end

This can then be used in Haml, like so:

    %html{html_attrs('fr-fr')}

This is compiled to:

    <html lang='fr-fr' xml:lang='fr-fr' xmlns='http://www.w3.org/1999/xhtml'>
    </html>

You can use as many such attribute methods as you want by separating them with
commas, like a Ruby argument list. All the hashes will be merged together, from
left to right. For example, if you defined

    def hash1
      {:bread => 'white', :filling => 'peanut butter and jelly'}
    end

    def hash2
      {:bread => 'whole wheat'}
    end

then

    %sandwich{hash1, hash2, :delicious => 'true'}/

would compile to:

    <sandwich bread='whole wheat' delicious='true' filling='peanut butter and jelly' />

Note that the Haml attributes list has the same syntax as a Ruby method call.
This means that any attribute methods must come before the hash literal.

Attribute methods aren't supported for HTML-style attributes.

#### Boolean Attributes

Some attributes, such as "checked" for `input` tags or "selected" for `option`
tags, are "boolean" in the sense that their values don't matter - it only
matters whether or not they're present. In HTML (but not XHTML), these
attributes can be written as

    <input selected>

To do this in Haml using hash-style attributes, just assign a Ruby `true` value
to the attribute:

    %input{:selected => true}

In XHTML, the only valid value for these attributes is the name of the
attribute. Thus this will render in XHTML as

    <input selected='selected'>

To set these attributes to false, simply assign them to a Ruby false value. In
both XHTML and HTML,

    %input{:selected => false}

will just render as:

    <input>

HTML-style boolean attributes can be written just like HTML:

    %input(selected)

or using `true` and `false`:

    %input(selected=true)

<!-- The title to the next section (Prefixed Attributes) has changed. This
<a> tag is so old links to here still work. -->
<a id="html5_custom_data_attributes" style="border:0;"></a>

#### Prefixed Attributes

HTML5 allows for adding
[custom non-visible data attributes](http://www.whatwg.org/specs/web-apps/current-work/multipage/elements.html#embedding-custom-non-visible-data-with-the-data-*-attributes)
to elements using attribute names beginning with `data-`. The
[Accessible Rich Internet Applications](http://www.w3.org/WAI/intro/aria)
specification makes use of attributes beginning with `aria-`. There are also
frameworks that use non-standard attributes with a common prefix.

Haml can help generate collections of attributes that share a prefix like
these. Any entry in an attribute hash that has a Hash as its value is expanded
into a series of attributes, one for each key/value pair in the hash, with the
attribute name formed by joining the “parent” key name to the key name with a
hyphen.

For example:

    %a{:href=>"/posts", :data => {:author_id => 123, :category => 7}} Posts By Author

will render as:

    <a data-author-id='123' data-category='7' href='/posts'>Posts By Author</a>

Notice that the underscore in `author_id` was replaced by a hyphen. If you wish
to suppress this behavior, you can set Haml's
{Haml::Options#hyphenate_data_attrs `:hyphenate_data_attrs` option} to `false`,
and the output will be rendered as:

    <a data-author_id='123' data-category='7' href='/posts'>Posts By Author</a>

This expansion of hashes is recursive – any value of the child hash that is
itself a hash will create an attribute for each entry, with the attribute name
prefixed with all ancestor keys. For example:

    .book-info{:data => {:book => {:id => 123, :genre => 'programming'}, :category => 7}}

will render as:

    <div class='book-info' data-book-genre='programming' data-book-id='123' data-category='7'></div>

### Class and ID: `.` and `#`

The period and pound sign are borrowed from CSS. They are used as shortcuts to
specify the `class` and `id` attributes of an element, respectively. Multiple
class names can be specified in a similar way to CSS, by chaining the class
names together with periods. They are placed immediately after the tag and
before an attributes hash. For example:

    %div#things
      %span#rice Chicken Fried
      %p.beans{ :food => 'true' } The magical fruit
      %h1.class.otherclass#id La La La

is compiled to:

    <div id='things'>
      <span id='rice'>Chicken Fried</span>
      <p class='beans' food='true'>The magical fruit</p>
      <h1 class='class otherclass' id='id'>La La La</h1>
    </div>

And,

    %div#content
      %div.articles
        %div.article.title Doogie Howser Comes Out
        %div.article.date 2006-11-05
        %div.article.entry
          Neil Patrick Harris would like to dispel any rumors that he is straight

is compiled to:

    <div id='content'>
      <div class='articles'>
        <div class='article title'>Doogie Howser Comes Out</div>
        <div class='article date'>2006-11-05</div>
        <div class='article entry'>
          Neil Patrick Harris would like to dispel any rumors that he is straight
        </div>
      </div>
    </div>

These shortcuts can be combined with long-hand attributes; the two values will
be merged together as though they were all placed in an array (see [the
documentation on `:class` and `:id` attributes](#class-and-id-attributes)). For
example:

    %div#Article.article.entry{:id => @article.number, :class => @article.visibility}

is equivalent to

    %div{:id => ['Article', @article.number], :class => ['article', 'entry', @article.visibility]} Gabba Hey

and could compile to:

    <div class="article entry visible" id="Article_27">Gabba Hey</div>

#### Implicit Div Elements

Because divs are used so often, they're the default elements. If you only define
a class and/or id using `.` or `#`, a div is automatically used. For example:

    #collection
      .item
        .description What a cool item!

is the same as:

    %div#collection
      %div.item
        %div.description What a cool item!

and is compiled to:

    <div id='collection'>
      <div class='item'>
        <div class='description'>What a cool item!</div>
      </div>
    </div>

#### Class Name Merging and Ordering

Class names are ordered in the following way:

1) Tag identifiers in order (aka, ".alert.me" => "alert me")
2) Classes appearing in HTML-style attributes
3) Classes appearing in Hash-style attributes

For instance, this is a complicated and unintuitive test case illustrating the ordering

    .foo.moo{:class => ['bar', 'alpha']}(class='baz')

The resulting HTML would be as follows:

    <div class='foo moo baz bar alpha'></div>

*Versions of Haml prior to 5.0 would alphabetically sort class names.*

### Empty (void) Tags: `/`

The forward slash character, when placed at the end of a tag definition, causes
Haml to treat it as being an empty (or void) element. Depending on the format,
the tag will be rendered either without a closing tag (`:html4` or `:html5`), or
as a self-closing tag (`:xhtml`).

Taking the following as an example:

    %br/
    %meta{'http-equiv' => 'Content-Type', :content => 'text/html'}/

When the format is `:html4` or `:html5` this is compiled to:

    <br>
    <meta content='text/html' http-equiv='Content-Type'>

and when the format is `:xhtml` it is compiled to:

    <br />
    <meta content='text/html' http-equiv='Content-Type' />

Some tags are automatically treated as being empty, as long as they have no
content in the Haml source. `meta`, `img`, `link`, `br`, `hr`, `input`,
`area`, `param`, `col` and `base` tags are treated as empty by default. This
list can be customized by setting the {Haml::Options#autoclose `:autoclose`}
option.

### Whitespace Removal: `>` and `<`

`>` and `<` give you more control over the whitespace near a tag. `>` will
remove all whitespace surrounding a tag, while `<` will remove all whitespace
immediately within a tag. You can think of them as alligators eating the
whitespace: `>` faces out of the tag and eats the whitespace on the outside, and
`<` faces into the tag and eats the whitespace on the inside. They're placed at
the end of a tag definition, after class, id, and attribute declarations but
before `/` or `=`. For example:

    %blockquote<
      %div
        Foo!

is compiled to:

    <blockquote><div>
      Foo!
    </div></blockquote>

And:

    %img
    %img>
    %img

is compiled to:

    <img /><img /><img />

And:

    %p<= "Foo\nBar"

is compiled to:

    <p>Foo
    Bar</p>

And finally:

    %img
    %pre><
      foo
      bar
    %img

is compiled to:

    <img /><pre>foo
    bar</pre><img />

### Object Reference: `[]`

Square brackets follow a tag definition and contain a Ruby object that is used
to set the class and id of that tag. The class is set to the object's class
(transformed to use underlines rather than camel case) and the id is set to the
object's class, followed by the value of its `#to_key` or `#id` method (in that
order). This is most useful for elements that represent instances of Active
Model models. Additionally, the second argument (if present) will be used as a
prefix for both the id and class attributes. For example:

    # file: app/controllers/users_controller.rb

    def show
      @user = CrazyUser.find(15)
    end

    -# file: app/views/users/show.haml

    %div[@user, :greeting]
      %bar[290]/
      Hello!

is compiled to:

    <div class='greeting_crazy_user' id='greeting_crazy_user_15'>
      <bar class='fixnum' id='fixnum_581' />
      Hello!
    </div>

If you require that the class be something other than the underscored object's
class, you can implement the `haml_object_ref` method on the object.

    # file: app/models/crazy_user.rb

    class CrazyUser < ActiveRecord::Base
      def haml_object_ref
        "a_crazy_user"
      end
    end

    -# file: app/views/users/show.haml

    %div[@user]
      Hello!

is compiled to:

    <div class='a_crazy_user' id='a_crazy_user_15'>
      Hello!
    </div>

The `:class` attribute may be used in conjunction with an object
reference.  The compiled element will have the union of all classes.

    - user = User.find(1)
    %p[user]{:class => 'alpha bravo'}
    <p id="user_1" class="alpha bravo user"></p>

## Doctype: `!!!`

When describing HTML documents with Haml, you can have a document type or XML
prolog generated automatically by including the characters `!!!`. For example:

    !!! XML
    !!!
    %html
      %head
        %title Myspace
      %body
        %h1 I am the international space station
        %p Sign my guestbook

is compiled to:

    <?xml version='1.0' encoding='utf-8' ?>
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html>
      <head>
        <title>Myspace</title>
      </head>
      <body>
        <h1>I am the international space station</h1>
        <p>Sign my guestbook</p>
      </body>
    </html>

You can also specify the specific doctype after the `!!!` When the
{Haml::Options#format `:format`} is set to `:xhtml`. The following doctypes are
supported:

`!!!`
: XHTML 1.0 Transitional<br/>
 `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">`

`!!! Strict`
: XHTML 1.0 Strict<br/>
 `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">`

`!!! Frameset`
: XHTML 1.0 Frameset<br/>
 `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">`

`!!! 5`
: XHTML 5<br/>
 `<!DOCTYPE html>`<br/>

`!!! 1.1`
: XHTML 1.1<br/>
 `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">`

`!!! Basic`
: XHTML Basic 1.1<br/>
 `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd"> `

`!!! Mobile`
: XHTML Mobile 1.2<br/>
 `<!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.2//EN" "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd">`

`!!! RDFa`
: XHTML+RDFa 1.0<br/>
 `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.0//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-1.dtd">`

When the {Haml::Options#format `:format`} option is set to `:html4`, the following
doctypes are supported:

`!!!`
: HTML 4.01 Transitional<br/>
 `<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">`

`!!! Strict`
: HTML 4.01 Strict<br/>
 `<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">`

`!!! Frameset`
: HTML 4.01 Frameset<br/>
 `<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">`

When the {Haml::Options#format `:format`} option is set to `:html5`,
`!!!` is always `<!DOCTYPE html>`.

If you're not using the UTF-8 character set for your document, you can specify
which encoding should appear in the XML prolog in a similar way. For example:

    !!! XML iso-8859-1

is compiled to:

    <?xml version='1.0' encoding='iso-8859-1' ?>

If the mime_type of the template being rendered is `text/xml` then a format of
`:xhtml` will be used even if the global output format is set to `:html4` or
`:html5`.

## Comments

Haml supports two sorts of comments: those that show up in the HTML output and
those that don't.

### HTML Comments: `/`

The forward slash character, when placed at the beginning of a line, wraps all
text after it in an HTML comment. For example:

    %peanutbutterjelly
      / This is the peanutbutterjelly element
      I like sandwiches!

is compiled to:

    <peanutbutterjelly>
      <!-- This is the peanutbutterjelly element -->
      I like sandwiches!
    </peanutbutterjelly>

The forward slash can also wrap indented sections of code. For example:

    /
      %p This doesn't render...
      %div
        %h1 Because it's commented out!

is compiled to:

    <!--
      <p>This doesn't render...</p>
      <div>
        <h1>Because it's commented out!</h1>
      </div>
    -->

#### Conditional Comments: `/[]`

You can also use [Internet Explorer conditional
comments](http://www.quirksmode.org/css/condcom.html) by enclosing the condition
in square brackets after the `/`. For example:

    /[if IE]
      %a{ :href => 'http://www.mozilla.com/en-US/firefox/' }
        %h1 Get Firefox

is compiled to:

    <!--[if IE]>
      <a href='http://www.mozilla.com/en-US/firefox/'>
        <h1>Get Firefox</h1>
      </a>
    <![endif]-->

To generate “downlevel-revealed” conditional comments, where the content is
hidden from IE but not other browsers,  add a `!` before the brackets: `/![]`.
Haml will produce valid HTML when generating this kind of conditional comment.

For example:

    /![if !IE]
      You are not using Internet Explorer, or are using version 10+.

is compiled to:

    <!--[if !IE]><!-->
      You are not using Internet Explorer, or are using version 10+.
    <!--<![endif]-->

### Haml Comments: `-#`

The hyphen followed immediately by the pound sign signifies a silent comment.
Any text following this isn't rendered in the resulting document at all.

For example:

    %p foo
    -# This is a comment
    %p bar

is compiled to:

    <p>foo</p>
    <p>bar</p>

You can also nest text beneath a silent comment. None of this text will be
rendered. For example:

    %p foo
    -#
      This won't be displayed
        Nor will this
                       Nor will this.
    %p bar

is compiled to:

    <p>foo</p>
    <p>bar</p>

## Ruby Evaluation

### Inserting Ruby: `=` {#inserting_ruby}

The equals character is followed by Ruby code. This code is evaluated and the
output is inserted into the document. For example:

    %p
      = ['hi', 'there', 'reader!'].join " "
      = "yo"

is compiled to:

    <p>
      hi there reader!
      yo
    </p>

If the {Haml::Options#escape_html `:escape_html`} option is set, `=` will sanitize
any HTML-sensitive characters generated by the script. For example:

    = '<script>alert("I\'m evil!");</script>'

would be compiled to

    &lt;script&gt;alert(&quot;I'm evil!&quot;);&lt;/script&gt;

`=` can also be used at the end of a tag to insert Ruby code within that tag.
For example:

    %p= "hello"

would be compiled to:

    <p>hello</p>

A line of Ruby code can be stretched over multiple lines as long as each line
but the last ends with a comma. For example:

    = link_to_remote "Add to cart",
        :url => { :action => "add", :id => product.id },
        :update => { :success => "cart", :failure => "error" }

Note that it's illegal to nest code within a tag that ends with `=`.

### Running Ruby: `-`

The hyphen character is also followed by Ruby code. This code is evaluated but
*not* inserted into the document.

**It is not recommended that you use this widely; almost all processing code and
logic should be restricted to Controllers, Helpers, or partials.**

For example:

    - foo = "hello"
    - foo << " there"
    - foo << " you!"
    %p= foo

is compiled to:

    <p>
      hello there you!
    </p>

A line of Ruby code can be stretched over multiple lines as long as each line
but the last ends with a comma. For example:

    - links = {:home => "/",
        :docs => "/docs",
        :about => "/about"}

#### Ruby Blocks

Ruby blocks, like XHTML tags, don't need to be explicitly closed in Haml.
Rather, they're automatically closed, based on indentation. A block begins
whenever the indentation is increased after a Ruby evaluation command. It ends
when the indentation decreases (as long as it's not an `else` clause or
something similar). For example:

    - (42...47).each do |i|
      %p= i
    %p See, I can count!

is compiled to:

    <p>42</p>
    <p>43</p>
    <p>44</p>
    <p>45</p>
    <p>46</p>
    <p>See, I can count!</p>

Another example:

    %p
      - case 2
      - when 1
        = "1!"
      - when 2
        = "2?"
      - when 3
        = "3."

is compiled to:

    <p>
      2?
    </p>

### Whitespace Preservation: `~` {#tilde}

`~` works just like `=`, except that it runs {Haml::Helpers#find\_and\_preserve}
on its input. For example,

    ~ "Foo\n<pre>Bar\nBaz</pre>"

is the same as:

    = find_and_preserve("Foo\n<pre>Bar\nBaz</pre>")

and is compiled to:

    Foo
    <pre>Bar&#x000A;Baz</pre>

See also [Whitespace Preservation](#whitespace_preservation).

### Ruby Interpolation: `#{}`

Ruby code can also be interpolated within plain text using `#{}`, similarly to
Ruby string interpolation. For example,

    %p This is #{h quality} cake!

is the same as

    %p= "This is #{h quality} cake!"

and might compile to:

    <p>This is scrumptious cake!</p>

Backslashes can be used to escape `#{}` strings, but they don't act as escapes
anywhere else in the string. For example:

    %p
      Look at \\#{h word} lack of backslash: \#{foo}
      And yon presence thereof: \{foo}

might compile to:

    <p>
      Look at \yon lack of backslash: #{foo}
      And yon presence thereof: \{foo}
    </p>

Interpolation can also be used within [filters](#filters). For example:

    :javascript
      $(document).ready(function() {
        alert(#{@message.to_json});
      });

might compile to:

    <script type='text/javascript'>
      //<![CDATA[
        $(document).ready(function() {
          alert("Hi there!");
        });
      //]]>
    </script>

#### Gotchas

Haml uses an overly simplistic regular expression to identify string
interpolation rather than a full-blown Ruby parser. This is fast and works for
most code but you may have errors with code like the following:

    %span #{'{'}

This code will generate a syntax error, complaining about unbalanced brackets.
In cases like this, the recommended workaround is output the code as a Ruby
string to force Haml to parse the code with Ruby.

    %span= "#{'{'}"


### Escaping HTML: `&=` {#escaping_html}

An ampersand followed by one or two equals characters evaluates Ruby code just
like the equals without the ampersand, but sanitizes any HTML-sensitive
characters in the result of the code. For example:

    &= "I like cheese & crackers"

compiles to

    I like cheese &amp; crackers

If the {Haml::Options#escape_html `:escape_html`} option is set, `&=` behaves
identically to `=`.

`&` can also be used on its own so that `#{}` interpolation is escaped. For
example,

    & I like #{"cheese & crackers"}

compiles to:

    I like cheese &amp; crackers

### Unescaping HTML: `!=` {#unescaping_html}

An exclamation mark followed by one or two equals characters evaluates Ruby code
just like the equals would, but never sanitizes the HTML.

By default, the single equals doesn't sanitize HTML either. However, if the
{Haml::Options#escape_html `:escape_html`} option is set, `=` will sanitize the
HTML, but `!=` still won't. For example, if `:escape_html` is set:

    = "I feel <strong>!"
    != "I feel <strong>!"

compiles to

    I feel &lt;strong&gt;!
    I feel <strong>!

`!` can also be used on its own so that `#{}` interpolation is unescaped.
For example,

    ! I feel #{"<strong>"}!

compiles to

    I feel <strong>!

## Filters {#filters}

The colon character designates a filter. This allows you to pass an indented
block of text as input to another filtering program and add the result to the
output of Haml. The syntax is simply a colon followed by the name of the filter.
For example:

    %p
      :markdown
        # Greetings

        Hello, *World*

is compiled to:

    <p>
      <h1>Greetings</h1>

      <p>Hello, <em>World</em></p>
    </p>

Filters can have Ruby code interpolated with `#{}`. For example:

    - flavor = "raspberry"
    #content
      :textile
        I *really* prefer _#{flavor}_ jam.

is compiled to

    <div id='content'>
      <p>I <strong>really</strong> prefer <em>raspberry</em> jam.</p>
    </div>

Note that `#{}` interpolation within filters is HTML-escaped if you specify true to
{Haml::Options#escape_filter_interpolations `:escape_filter_interpolations`} option.

The functionality of some filters such as Markdown can be provided by many
different libraries. Usually you don't have to worry about this - you can just
load the gem of your choice and Haml will automatically use it.

However in some cases you may want to make Haml explicitly use a specific gem to
be used by a filter. In these cases you can do this via Tilt, the library Haml
uses to implement many of its filters:

    Tilt.prefer Tilt::RedCarpetTemplate

See the [Tilt documentation](https://github.com/rtomayko/tilt#fallback-mode) for
more info.

Haml comes with the following filters defined:

### `:cdata` {#cdata-filter}

Surrounds the filtered text with CDATA tags.

### `:coffee` {#coffee-filter}

Compiles the filtered text to JavaScript in `<script>` tag using CoffeeScript.
You can also reference this filter as `:coffeescript`. This filter is
implemented using Tilt.

### `:css` {#css-filter}

Surrounds the filtered text with `<style>` and (optionally) CDATA tags. Useful
for including inline CSS. Use the {Haml::Options#cdata `:cdata` option} to
control when CDATA tags are added.

### `:erb` {#erb-filter}

Parses the filtered text with ERB, like an RHTML template. Not available if the
{Haml::Options#suppress_eval `:suppress_eval`} option is set to true. Embedded
Ruby code is evaluated in the same context as the Haml template. This filter is
implemented using Tilt.

### `:escaped` {#escaped-filter}

Works the same as plain, but HTML-escapes the text
before placing it in the document.

### `:javascript` {#javascript-filter}

Surrounds the filtered text with `<script>` and (optionally) CDATA tags.
Useful for including inline Javascript. Use the {Haml::Options#cdata `:cdata`
option} to control when CDATA tags are added.

### `:less` {#less-filter}

Parses the filtered text with [Less](http://lesscss.org/) to produce CSS output in `<style>` tag.
This filter is implemented using Tilt.

### `:markdown` {#markdown-filter}

Parses the filtered text with
[Markdown](http://daringfireball.net/projects/markdown). This filter is
implemented using Tilt.

### `:maruku` {#maruku-filter}

Parses the filtered text with [Maruku](https://github.com/nex3/maruku), which
has some non-standard extensions to Markdown.

As of Haml 4.0, this filter is defined in [Haml
contrib](https://github.com/haml/haml-contrib) but is loaded automatically for
historical reasons. In future versions of Haml it will likely not be loaded by
default. This filter is implemented using Tilt.

### `:plain` {#plain-filter}

Does not parse the filtered text. This is useful for large blocks of text
without HTML tags, when you don't want lines starting with `.` or `-` to be
parsed.

### `:preserve` {#preserve-filter}

Inserts the filtered text into the template with whitespace preserved.
`preserve`d blocks of text aren't indented, and newlines are replaced with the
HTML escape code for newlines, to preserve nice-looking output. See also
[Whitespace Preservation](#whitespace_preservation).

### `:ruby` {#ruby-filter}

Parses the filtered text with the normal Ruby interpreter. Creates an `IO`
object named `haml_io`, anything written to it is output into the Haml document.
Not available if the {Haml::Options#suppress_eval `:suppress_eval`} option is
set to true. The Ruby code is evaluated in the same context as the Haml
template.

### `:sass` {#sass-filter}

Parses the filtered text with [Sass](http://sass-lang.com/) to produce CSS
output in `<style>` tag. This filter is implemented using Tilt.

### `:scss` {#scss-filter}

Parses the filtered text with Sass like the `:sass` filter, but uses the newer
SCSS syntax to produce CSS output in `<style>` tag. This filter is implemented
using Tilt.

### `:textile` {#textile-filter}

Parses the filtered text with [Textile](http://www.textism.com/tools/textile).
Only works if [RedCloth](http://redcloth.org) is installed.

As of Haml 4.0, this filter is defined in [Haml
contrib](https://github.com/haml/haml-contrib) but is loaded automatically for
historical reasons. In future versions of Haml it will likely not be loaded by
default. This filter is implemented using Tilt.

### Custom Filters

You can also define your own filters. See {Haml::Filters} for details.

## Helper Methods {#helper-methods}

Sometimes you need to manipulate whitespace in a more precise fashion than what
the whitespace removal methods allow. There are a few helper methods that are
useful when dealing with inline content. All these methods take a Haml block to
modify.

### surround {#surround}

Surrounds a Haml block with text. Expects 1 or 2 string arguments used to
surround the Haml block. If a second argument is not provided, the first
argument is used as the second.

    = surround "(", ")" do
      = link_to "learn more", "#"

### precede {#precede}

Prepends a Haml block with text. Expects 1 argument.

    = precede "*" do
      %span Required

### succeed {#succeed}

Appends a Haml block with text. Expects 1 argument.

    Begin by
    = succeed "," do
      = link_to "filling out your profile", "#"
    = succeed "," do
      = link_to "adding a bio", "#"
    and
    = succeed "." do
      = link_to "inviting friends", "#"

## Multiline: `|` {#multiline}

The pipe character designates a multiline string.
It's placed at the end of a line (after some whitespace)
and means that all following lines that end with `|`
will be evaluated as though they were on the same line.
**Note that even the last line in the multiline block
should end with `|`.**
For example:

    %whoo
      %hoo= h(                       |
        "I think this might get " +  |
        "pretty long so I should " + |
        "probably make it " +        |
        "multiline so it doesn't " + |
        "look awful.")               |
      %p This is short.

is compiled to:

    <whoo>
      <hoo>I think this might get pretty long so I should probably make it multiline so it doesn't look awful.</hoo>
      <p>This is short</p>
    </whoo>

Using multiline declarations in Haml is intentionally awkward.
This is designed to discourage people from putting lots and lots of Ruby code
in their Haml templates.
If you find yourself using multiline declarations, stop and think:
could I do this better with a helper?

Note that there are a few cases where it's useful to allow
something to flow over onto multiple lines in a non-awkward manner.
One of these is HTML attributes.
Some elements just have lots of attributes,
so you can wrap attributes without using `|` (see [Attributes](#attributes)).

In addition, sometimes you need to call Ruby methods or declare data structures
that just need a lot of template information.
So data structures and  functions that require lots of arguments
can be wrapped over multiple lines,
as long as each line but the last ends in a comma
(see [Inserting Ruby](#inserting_ruby)).

## Whitespace Preservation

Sometimes you don't want Haml to indent all your text.
For example, tags like `pre` and `textarea` are whitespace-sensitive;
indenting the text makes them render wrong.

Haml deals with this by "preserving" newlines before they're put into the
document -- converting them to the HTML whitespace escape code, `&#x000A;`. Then
Haml won't try to re-format the indentation.

Literal `textarea` and `pre` tags automatically preserve content given through
`=`. Dynamically-generated `textarea`s and `pre`s can't be preserved
automatically, and so should be passed through
{Haml::Helpers#find\_and\_preserve} or the [`~` command](#tilde), which has the
same effect.

Blocks of literal text can be preserved using the [`:preserve` filter](#preserve-filter).

## Helpers

Haml offers a bunch of helpers that are useful for doing stuff like preserving
whitespace, creating nicely indented output for user-defined helpers, and other
useful things. The helpers are all documented in the {Haml::Helpers} and
{Haml::Helpers::ActionViewExtensions} modules.