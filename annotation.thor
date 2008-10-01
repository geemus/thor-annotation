# thanks Jamis!

class SourceAnnotationExtractor

  class Annotation < Struct.new(:line, :tag, :text)

    def to_s(options={})
      s = "[%3d] " % line
      s << "[#{tag}] " if options[:tag]
      s << text
    end
  end

  def self.enumerate(tag, options={})
    extractor = new(tag)
    extractor.display(extractor.find, options)
  end

  attr_reader :tag

  def initialize(tag)
    @tag = tag
  end

  def find(dirs=%w(app lib test))
    dirs.inject({}) { |h, dir| h.update(find_in(dir)) }
  end

  def find_in(dir)
    results = {}

    Dir.glob("#{dir}/*") do |item|
      next if File.basename(item)[0] == ?.

      if File.directory?(item)
        results.update(find_in(item))
      elsif item =~ /\.(?:rb|rxml|xerb|builder|mab|haml)$/
        results.update(extract_annotations_from(item, /#\s*(#{tag}):?\s*(.*)$/))
      elsif item =~ /\.herb|\.jerb|\.erb$/
        results.update(extract_annotations_from(item, /<%\s*#\s*(#{tag}):?\s*(.*?)\s*%>/))
      end
    end

    results
  end

  def extract_annotations_from(file, pattern)
    lineno = 0
    result = File.readlines(file).inject([]) do |list, line|
      lineno += 1
      next list unless line =~ pattern
      list << Annotation.new(lineno, $1, $2)
    end
    result.empty? ? {} : { file => result }
  end

  def display(results, options={})
    results.keys.sort.each do |file|
      puts "#{file}:"
      results[file].each do |note|
        puts "  * #{note.to_s(options)}"
      end
      puts
    end
  end

end

class Notes < Thor

  desc 'all', 'Enumerate all annotations'
  def all
    SourceAnnotationExtractor.enumerate 'FIXME|OPTIMIZE|TODO', :tag => true
  end

  desc 'doc', 'Enumerate all DOC annotations'
  def doc
    SourceAnnotationExtractor.enumerate 'DOC'
  end

  desc 'fixme', 'Enumerate all FIXME annotations'
  def fixme
    SourceAnnotationExtractor.enumerate 'FIXME'
  end

  desc 'optimize', 'Enumerate all OPTIMIZE annotations'
  def optimize
    SourceAnnotationExtractor.enumerate 'TODO'
  end

  desc 'todo', 'Enumerate all TODO annotations'
  def todo
    SourceAnnotationExtractor.enumerate 'TODO'
  end

end