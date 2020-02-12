using Documenter, DateSelectors

makedocs(;
    modules=[DateSelectors],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://gitlab.invenia.ca/invenia/DateSelectors.jl/blob/{commit}{path}#L{line}",
    sitename="DateSelectors.jl",
    authors="Invenia Technical Computing Corporation",
    assets=[
        "assets/invenia.css",
        "assets/logo.png",
    ],
    strict=true,
    html_prettyurls=false,
    checkdocs=:none,
)
