% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/WhatsappChatCleaner.R
\name{make_emoji_count_column}
\alias{make_emoji_count_column}
\title{Make column with emoji count}
\usage{
make_emoji_count_column(emoji_data, text_data)
}
\arguments{
\item{emoji_data}{, data frame}

\item{text_data}{, data frame}
}
\description{
This function creates new column for each emoji with their count.
}
\examples{
clean_data_without_media_with_emoji <- make_emoji_count_column(emoji_all, clean_data_without_media)
}

