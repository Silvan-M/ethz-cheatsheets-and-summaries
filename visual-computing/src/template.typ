// The project function defines how your document looks.
// It takes your content and some metadata and formats it.
// Go ahead and customize it to your liking!
#let project(title: "", authors: (), date: none, body) = {
  // Set the document's basic properties.
  set document(author: authors.map(a => a.name), title: title)
  set page(numbering: "1/1", number-align: center, flipped: true, margin: 3em)
  set text(font: "New Computer Modern", lang: "en", size: 10pt)

  set heading(numbering: "1.1")
  set par(leading: 0.58em)

  // Make block math display more compact.
  show math.equation.where(block: true): set block(spacing: 0.6em)
  
  show: columns.with(3, gutter: 2.5em)

  // Title row.
  align(center)[
    #block(text(1.5em, {smallcaps("Cheat Sheet")}))
    #block(text(weight: 700, 1.85em, title), above: 1em)
    #v(0.6cm, weak: true)
  ]

  // Author information.
  pad(
    top: 0.3em,
    bottom: -0.65em,
    align(center)[
      #text(size: 1.25em, style: "italic", {
        authors.map(author => link("mailto:" + author.email, author.name)).join(", ")
      })
    ]
  )
  align(center)[
    #text(datetime.today().display("[month repr:long] [year]"), size: 1.05em)
    #v(0.2cm)
  ]
  align(center, text(size: 10pt)[
    #text("License: ", weight: "bold")CC BY-SA 4.0\
  ])

  // Main body.
  set par(justify: true)
  //set text(size: 0.85em)

  body
}

#let colorbox(title: none, inline: true, breakable: true, color: rgb(0, 126, 253), content) = {
  let colorOutset = 6pt
  let titleContent = if title != none {
    box(
      fill: color.lighten(85%), 
      outset: colorOutset,
      width: 100%,
      radius: {(top-left: 4pt, top-right: 4pt)},
      [*#title*]) + if inline { h(6pt) }
  }

  block(
    outset: (top: colorOutset, rest: colorOutset),
    fill: color.lighten(95%), 
    breakable: breakable,
    width: 100%,
    radius: 4pt,
    above: 1.5em,
    below: 1.5em,
    
    titleContent + v(0pt)+ content)
}


#let slashCircle = symbol("\u{2298}")


/*
// Apply inline only if it minimizes height.
#let colorbox(title: none, inline: none, breakable: true, color: blue, content) = {
  style((styles) => {
      let meas1 = measure(colorbox_s(title: title, inline: true, breakable: breakable, color: color, content), styles)
      let meas2 = measure(colorbox_s(title: title, inline: false, breakable: breakable, color: color, content), styles)
      let inline = meas1.height < meas2.height
    colorbox_s(title: title, inline: inline, breakable: breakable, color: color, content)
  })
}
*/