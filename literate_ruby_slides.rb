#!/usr/bin/env ruby

require 'erb'
require 'pp'

class LiterateRubySlideGenerator
  EMPTY_HASH = { }.freeze
  EMPTY_ARRAY = [ ].freeze
  EMPTY_STRING = ''.freeze

  attr_reader :slides, :lines

  attr_accessor :slides_dir, :slides_basename

  def initialize opts = nil
    opts ||= EMPTY_HASH
    @slide_stack = [ ]
    @slide = nil
    @slides = [ ]
    @lines = [ ]
    @slides_dir = '.'
    @slides_basename = nil
    opts.each do | k, v |
      send(:"#{k}=", v)
    end
  end
  
  def process_file! file_name
    @file_name = file_name
    @slides_basename ||= File.basename(file_name, '.rb')
    process_file_contents! File.read(file_name)
    $stderr.puts "Processed #{file_name}"
    self
  end
  
  def process_file_contents! file_contents
    file_lines = file_contents.split("\n")
    @file_line = 0
    until file_lines.empty?
      line = file_lines.shift
      @file_line += 1
      
      # $stderr.puts "#{@file_name}:#{"%5d" % @file_line}: #{line}"
      @lines << line

      case line
      when /^(\s*)\#\s*!SLIDE\s*(.*)/
        indention, command = $1, $2
        
        # $stderr.puts "#{@file_name}:#{"%5d" % @file_line}: command = #{command.inspect}"

        args = { }
        command.gsub!(/:(\w+)\s+([^:]+)/) do | *x |
          # $stderr.puts "  name = #{$1.to_sym.inspect} => #{$2.inspect}"
          args[$1.to_sym] = $2
          ''
        end
        # $stderr.puts "#{@file_name}:#{"%5d" % @file_line}: args = #{args.inspect}" if ! args.empty?
        # $stderr.puts "#{@file_name}:#{"%5d" % @file_line}: command = #{command.inspect}"

        case command
        when /^end\b/i
          while @slide && indention <= @slide.indention
            end_slide
          end
        when /^(\w+)\s+(\S+)/
          slot, value = $1, $2
          @slide.send(:"#{slot}=", $2)
        when /^(pause|resume)\b/ 
          @slide.send(:"#{$1}!")
        when /^begin\b/i
          args[:indention] = indention
          start_slide args
        when ''
          while @slide && indention <= @slide.indention
            end_slide
          end
          args[:indention] = indention
          start_slide args
        else
          raise "#{@file_name}:#{@file_line}: unknown command #{line}"
        end
      else
        if @slide 
           if ! @slide.title && line =~ /^\s*#\s+(.+)/
             @slide.title = $1
           else
             @slide.lines << line unless @slide.paused
           end
        end
      end
    end
  end

  def start_slide opts
    @slide_stack.push @slide
    parent_slide = @slide
    @slide = Slide.new opts
    @slide.owner = self
    @slide.superslide = parent_slide
    @slide.file_name = @file_name
    @slide.file_line = @file_line
    @slides << @slide
    if parent_slide
      unless parent_slide.paused
        parent_slide.subslides << @slide 
        parent_slide.lines << @slide
      end
    end
    @slide
  end

  def end_slide
    @slide = @slide_stack.pop
  end

  def render_slides io
    max_index = @slides.map{|s| s.index}.compact.sort[-1]
    max_index ||= 1
    @slides.each do | slide |
      slide.index ||= (max_index += 1)
    end
    @slides.sort! { | a, b | a.index <=> b.index }
    i = 0;
    @slides.each do | slide |
      $stderr.puts "#{"%3d" % (i += 1)} - @#{"%3d" % slide.index} - #{slide.title_string}"
      slide.render_slide(io)
    end
  end
  

  def slides_basename
    @slides_basename ||=
      'slides'
  end

  def slides_dirname
    @slides_dirname ||=
      "#{slides_dir}/#{slides_basename}.slides"
  end
 
  def slides_textile
    @slides_textile ||=
      "#{slides_dirname}.textile"
  end

  def slides_textile_erb 
    @slides_textile_erb ||=
      "#{slides_textile}.erb"
  end

  def render_slides_textile!
    File.open(slides_textile_erb, "w+") do | io |
      render_slides io
    end
    $stderr.puts "Created #{slides_textile_erb}"
    
    erb = ERB.new(File.read(erb_file = slides_textile_erb))
    erb.filename = erb_file
    textile = erb.result(binding)

    textile.gsub!(/"":relative:([^\s]+)/){|x| %Q{<a href="#{$1}">#{$1}</a>}}
    textile.gsub!(/"":(https?:[^\s]+)/){|x| %Q{"#{$1}":#{$1}}}

    File.open(slides_textile, "w+") { | out | out.puts textile }

    $stderr.puts "Created #{slides_textile}"

    self
  end

  def render_slides_html!
    render_slides_textile!

    slides = slides_dirname

    scarlet = (ENV['SCARLET'] ||= File.expand_path("~/local/src/scarlet/bin/scarlet"))

    dirs = %w(stylesheets javascripts image)
    system "set -x; mkdir -p #{slides} #{dirs.map{|d| "#{slides}/#{d}"} * " "}"

    system "set -x; #{scarlet} -f html #{slides_textile} > #{slides}/index.html"

    dirs.each do | d |
      system "set -x; cp -p #{d}/*.* #{slides}/#{d}/" if File.directory?(d)
    end

    $stderr.puts "Created #{slides}"

    self
  end


  class Slide
    attr_accessor :index, :name, :file_name, :file_line, :title
    attr_accessor :owner, :superslide, :subslides
    attr_accessor :lines, :indention
    attr_accessor :capture_code_output

    attr_accessor :paused

    def initialize opts
      @superslide = nil
      @subslides = [ ]
      @lines = [ ]
      opts.each do | k, v |
        send(:"#{k}=", v)
      end
      @paused = false
    end

    def index= i
      @index = i && i.to_i
    end

    def pause!
      $stderr.puts "  Slide #{title_string} pause!"
      @paused = true
    end
    def resume!
      $stderr.puts "  Slide #{title_string} resume!"
      @paused = false
    end

    def superslides
      return @superslides if @superslides
      @superslides = [ ]
      s = @superslide
      while s
        @superslides << s
        s = s.superslide
      end
      @superslides
    end

    def render_slide io
      # io.puts ""
      io.puts "!SLIDE"
      io.puts ""
      io.puts "h1. #{title_string}"
      io.puts ""

      # Remove blank lines at end.
      begin
        lines.pop
      end while (last_line = lines.last) && String === last_line && last_line =~ /^\s*$/
      
      # Remove multiple blank lines.
      (0 ... lines.size).each do | i |
        if blank_line?(lines[i]) && blank_line?(lines[i + 1])
          lines.delete(i)
        end
      end

      # Render slide body.
      in_ruby = false
      body.each do | line |
        if (! ! line =~ /^\s\s/) != ! ! in_ruby
          in_ruby = ! in_ruby
          io.puts "" if in_ruby
          io.puts "@@@ ruby"
          io.puts "" if ! in_ruby
        end
        io.puts line
      end

      io.puts ""

      unless code.empty?
        io.puts "@@@ ruby"
        render_slide_code io
        io.puts "@@@"
        io.puts ""

        if capture_code_output
          lines_per_slide = 15
          $stderr.puts "  Code Output:"
          @code_output = capture_code_output!
          code_output_lines = @code_output.split("\n")
          # $stderr.puts PP.pp(code_output_lines, '')
          $stderr.puts "    #{code_output_lines.size} lines (#{lines_per_slide} lines / page)"
          # Prevent empty pages
          code_output_lines << EMPTY_STRING if code_output_lines.empty? 
          page = 0
          until code_output_lines.empty?
            page += 1
            page_lines = code_output_lines[0, lines_per_slide]
            code_output_lines[0, lines_per_slide] = EMPTY_ARRAY
            break if page_lines.empty?
            $stderr.puts "    Page #{page} - #{page_lines.size} lines"
            io.puts "!SLIDE"
            io.puts ""
            io.puts "h1. #{title_string} - Output #{page > 1 ? "- Page #{page}" : ""}"
            io.puts ""
            io.puts "@@@"
            io.puts page_lines * "\n"
            io.puts "@@@"
            io.puts "MORE ..." unless code_output_lines.empty?
            io.puts ""
          end
        end
      end
      
    end


    def render_slide_code io
      # Render slide code.
      superslides.reverse.each do | s |
        io.puts s.ruby_block_start_line if s.ruby_block_start_line
      end
      
      last_line = nil
      code.each do | line |
        last_line = line
        case line
        when Slide
          line.render_subslide io
        else
          io.puts line
        end
      end
      
      if ruby_block_start_line && indention == '' && last_line != 'end'
        io.puts "end"
      end
      
      superslides.each do | s |
        io.puts s.ruby_block_end_line if s.ruby_block_end_line
      end
    end


    def blank_line? line
      line && String === line && line =~ /^\s*$/
    end


    def render_subslide io
      io.puts "#{indention}# #{title_string}"
      if ruby_block_start_line
        io.puts ruby_block_start_line + "; ...; end " 
      else
        io.puts "#{indention}# ..."
      end
    end


    def title_string
      "#{title || "SLIDE:#{file_name}:#{file_line}"}"
    end


    def body
      return @body if @body
      extract_body_and_code!
      @body
    end


    def code
      return @code if @code
      extract_body_and_code!
      @code
    end


    def extract_body_and_code!
      @body = [ ]
      @code = [ ]
      comment_indent = "\\s*"
      first_comment_indent = 0

      lines = self.lines.dup
      until lines.empty?
        line = lines.shift
        break unless String === line
        case line
        when /^#{indention}#(#{comment_indent})(.*)/
          unless first_comment_indent
            first_comment_indent = comment_indent = $1
          end
          @body << $2
        else
          @code << line
          break
        end
      end

      until lines.empty?
        line = lines.shift
        @code << line
      end
    end


    def ruby_block_start_line
      (@ruby_block_start_line ||= [ find_ruby_block_start_line ]).first
    end


    def find_ruby_block_start_line
      lines.each do | line |
        case line
        when /^#{indention}(def|class|module|begin)\b(.*)/
          return line
        end
      end
      nil
    end


    def ruby_block_end_line
      (@ruby_block_end_line ||= [ ruby_block_start_line ? "#{indention}end" : nil ]).first
    end


    def capture_code_output!
      $stderr.puts "  Capturing code output at #{file_name}:#{file_line} for #{title_string.inspect}"

      rb = "capture.rb"
      file = "#{rb}.out"

      prog = [ ]
      prog << <<"END"
    def __capture_stream cur_stream, new_stream
      old_stream = cur_stream.clone
      cur_stream.reopen(new_stream)
      yield
    ensure
      cur_stream.reopen(old_stream)
    end

END

      owner.lines[0 ... file_line].each do | lines |
        prog << lines
      end

      prog << <<"END"
      File.open(#{file.inspect}, 'w') do | log |
        __capture_stream $stdout, log do
          __capture_stream $stderr, log do
END
    
      code.each do | line |
        prog << line
      end
    
      prog << <<"END"
          end
        end
      end
      exit 0
END
      prog = prog * "\n"
      File.open(rb, "w+") { | fh | fh.puts prog }
      system("ruby #{rb.inspect} >/dev/null 2>&1")
    
      File.read(file) rescue ''
    ensure
      #File.unlink(file) rescue nil
      #File.unlink(rb) rescue nil
    end
  end
end


######################################################################

obj = LiterateRubySlideGenerator.new
ARGV.each do | file_name |
  obj.process_file!(file_name)
end

obj.render_slides_html!

exit 0



