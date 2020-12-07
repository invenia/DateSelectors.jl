using Documenter
using DateSelectors
using Dates
using Intervals

makedocs(;
    modules=[DateSelectors],
    format=Documenter.HTML(
        prettyurls=false,
        assets=[
            "assets/invenia.css",
        ],
    ),
    pages=[
        "Home" => "index.md",
        "API" => "api.md",
        "Examples" => "examples.md"
    ],
    repo="https://gitlab.invenia.ca/invenia/research/DateSelectors.jl/blob/{commit}{path}#L{line}",
    sitename="DateSelectors.jl",
    authors="Invenia Technical Computing Corporation",
    strict=false,
    checkdocs=:none,
)
