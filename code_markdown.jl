function make_markdown_page(codeentry, metadata)
    family_strs = ["($(join(string.(s),", ")))" for s in metadata[:family]] # otherwise there is an annoying trailing comma
    rendered = render_from_file("code_template.md", (;codeentry, metadata..., family_strs))
    write("codes/$codeentry/index.md", rendered)
end
