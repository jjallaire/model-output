---@diagnostic disable: redundant-return-value, assign-type-mismatch

tinyyaml = require('tinyyaml')

function Meta(meta)
  quarto.doc.add_html_dependency({
    name = 'model-output',
    stylesheets = { 'model-output.css' }
  })
end

function CodeBlock(el)
  if el.classes:includes("model-output") then
    model_output = tinyyaml.parse(el.text)
    conversation = pandoc.Blocks({})

    function handle_role(role, message)
      if message[role] then
        conversation:insert(pandoc.Div({
          pandoc.Para({
            role_text(role),
            pandoc.Str(message[role]),
          }),
          pandoc.RawBlock("latex", "\\vspace{1em}")
        }, pandoc.Attr("", { "model-message" })))
      end
    end

    function handle_separator(message)
      if message == 'separator' then
        conversation:insert(separator())
      end
    end

    for _, message in pairs(model_output) do
      handle_role("system", message)
      handle_role("user", message)
      handle_role("assistant", message)
      handle_separator(message)
    end

    -- return a callout
    return quarto.Callout({
      type = "none",
      appearance = "minimal",
      content = conversation
    })
  end
end

role_colors = {
  user = "purple",
  assistant = "red",
}

function role_text(role)
  role_caption = role:gsub("^%l", string.upper) .. ": "

  if quarto.doc.is_format("pdf") then
    role_color = role_colors[role]
    if role_color then
      return pandoc.Strong({ pandoc.RawInline("latex", "\\textcolor{" .. role_color .. "}{" .. role_caption .. "}") })
    else
      return pandoc.Strong(role_caption)
    end
  else
    return pandoc.Span(
      pandoc.Strong(role_caption),
      pandoc.Attr("", { "role-" .. role })
    )
  end
end

function separator()
  if quarto.doc.is_format("latex") then
    return pandoc.RawBlock("latex", "\\noindent\\rule{\\textwidth}{1pt}\\vspace{1em}")
  else
    return pandoc.HorizontalRule()
  end
end
