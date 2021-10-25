using Documenter
using ParserPWF

makedocs(
    modules = [ParserPWF],
    format = Documenter.HTML(analytics = "UA-367975-10", mathengine = Documenter.MathJax()),
    sitename = "ParserPWF",
    authors = "Iago Chávarry and Pedro Hamacher",
    pages = [
        "Home" => "index.md",
        "Manual" => [
            "Getting Started" => "quickguide.md",
        ],
        "PWF File" => [
            "Overview" => "pwf_overview.md",
            "DBAR" => "dbar.md",
            "DLIN" => "dlin.md",
            "DGER" => "dger.md",
            "DGBT" => "dgbt.md",
            "DGLT" => "dglt.md",
            "DSHL" => "dshl.md",
            "DELO" => "delo.md",
            "DCBA" => "dcba.md",
            "DCLI" => "dcli.md",
            "DCNV" => "dcnv.md",
            "DCCV" => "dccv.md",
            "DBSH" => "dbsh.md",
            "DCER" => "dcer.md",
            "DCSC" => "dcsc.md",
            "DOPC" => "dopc.md",
            "DCTE" => "dcte.md",
        ],
    ]
)


# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
