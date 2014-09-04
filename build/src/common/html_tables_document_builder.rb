require 'stringio'
require 'cgi'
# sample usage:
# tables_builder = HTMLTablesDocumentBuilder.new
# tables_builder.add_table(nil, [["1", "one", "unos"], ["2", "two", "dos"]])
# tables_builder.add_table(["Room ID", "Person Name"], [["5", "Jack"], ["9", "Jill"]])
# html_document = tables_builder.to_html; puts html_document
class HTMLTablesDocumentBuilder
	def initialize
		@tables = []
	end
	
	def add_table(headers, rows)
		table = {}
		if headers != nil
			table[:headers] = headers
		end
		table[:rows] = rows
		@tables.push(table)
	end
	
	def to_html
		StringIO.open('', 'w') do |string_io|
			write_document_start(string_io)
			@tables.each do |table|
				write_table_html(string_io, table)
			end
			write_document_end(string_io)
			
			string_io.string
		end
	end
	
	def to_s
		@tables.inspect
	end
	
	private
	
	def write_table_html(io, table)
		io.puts("<table>")
		if table[:headers]
			write_row_of_ths(io, table[:headers])
		end
		table[:rows].each do |row|
			write_row_of_tds(io, row)
		end
		io.puts("</table>")
	end
	
	def write_row_of_ths(io, th_contents)
		write_row_of_tags(io, th_contents, 'th')
	end
	
	def write_row_of_tds(io, td_contents)
		write_row_of_tags(io, td_contents, 'td')
	end
	
	def write_row_of_tags(io, tag_contents, tag_name)
		io.puts "<tr>"
		tag_contents.each do |contents|
			io.puts "  " + "<#{tag_name}>" + html_escape(contents) + "</#{tag_name}>"
		end
		io.puts "</tr>"
	end
	
	def html_escape(text)
		CGI::escapeHTML(text)
	end

	def write_document_start(io)
		io.puts "<html>"
		io.puts "<body>"
	end

	def write_document_end(io)
		io.puts "</body>"
		io.puts "</html>"
	end
end
