#=======================================================================================
#
# File:        WhatsappChatCleaner.R
# Author:      Junaid Effendi
# Description: This is a whatsapp chat cleaner package, cleans the data and help to extract emojis.
#
#=======================================================================================

#========================================================
# Install and Load Packages
#========================================================
#' Install and Load Libraries
#'
#' This function installs and loads required libraries
#' @examples
#' install_load_packages()
install_load_packages <- function()
{
  install.packages("stringr", "dplyr", "zoo")
  library("stringr")
  library("dplyr")
  library("zoo")
}

#========================================================
# Function to clean whatsapp chat
#========================================================
#' Cleans whatsapp chat data
#'
#' This function takes the raw chat file and makes it clean for analysis.
#' @param filepath , string, enter file path or file name if present in the same directory
#' @keywords media 
#' @examples
#' clean_data <- clean_whatsapp_chat("whatsapp_friends.txt")
clean_whatsapp_chat <- function(filepath)
{
  all_data = readLines(filepath)
  #Removing the first message
  all_data = all_data[-1]
  
  #Extracting date and time  
  date_time <- format(strptime(all_data, "%m/%d/%y, %I:%M %p"),"%m/%d/%y, %H:%M")
  head(date_time)
  
  #Extracting date
  date = gsub(",.*$","",date_time) #Fetching all before ","
  
  #Extracting time
  time = gsub("^.*,","",date_time) #Fetching all after ","
  time = str_trim(time) #Removing spaces from both ends
  time 
  
  sender <- 'sender' #Temorary Data
  message <- all_data
  
  #Creating Data Frame
  clean_data = data.frame(date,time,sender,message)
  head(clean_data)
  
  #Extracting sender and message from the data frame
  #Fetching only complete cases
  sender_message = clean_data[complete.cases(clean_data),4] 
  sender_message = gsub("^.*?-","",sender_message)
  sender_message = str_trim(sender_message) 
  
  #Extracting message
  message = gsub("^.*?:","",sender_message) 
  message = str_trim(message) #Removing spaces from both ends
  head(message)
  #Updating the data frame with new message data
  clean_data$message <- as.character(clean_data$message)
  clean_data[complete.cases(clean_data),4] <- message
  
  #Extracting sender names
  sender = gsub("?:.*$","",sender_message) 
  sender = str_trim(sender) #Removing spaces from both ends
  head(sender) 
  #Updating the data frame with new sender data
  clean_data$sender <- as.character(clean_data$sender)
  clean_data[complete.cases(clean_data),3] <- sender
  
  #Replacing remaining "sender" values with NA
  clean_data[clean_data=="sender"]<- NA
  
  
  #Using transform function from Zoo Package 
  #Filling NA with previous values
  #Detailed explanation > www.tensorflowhub.org
  clean_data <- transform(clean_data, date = na.locf(date), time = na.locf(time),
                          sender = na.locf(sender))
  
  #Refactorizing 
  clean_data$sender <- as.factor(clean_data$sender)
  
  return(clean_data)
}


#========================================================
# Function to create data frame without media
#========================================================
#' Remove media records
#'
#' This function removes all the media messages rows from the data frame.
#' @param clean_data , data frame
#' @keywords media 
#' @examples
#' clean_data_without_media <- media_remove(clean_data)
media_remove <- function(clean_data)
{
  clean_data_without_media <- clean_data
  clean_data_without_media[clean_data_without_media=="<Media omitted>"] <- NA
  clean_data_without_media <- clean_data_without_media[complete.cases(clean_data_without_media),]
  head(clean_data_without_media)
  
  return(clean_data_without_media)
}

#========================================================
# Emoji Loader Function
#========================================================
#' Load Emojis from file
#'
#' This function loads the emojis from csv file and cleans them for usage. 
#' @param filepath , string, enter file path or file name if present in the same directory
#' @examples
#' emoji_all = emoji_loader("whatsapp_emoji_all.csv")
emoji_loader <- function(filepath)
{
  emoji_data = read.csv(filepath)
  head(emoji_data)
  
  #Adding emoji- to each name to extract patterns with accuracy
  emoji_data$Names <- paste0("emoji-", emoji_data$Names)
  emoji_data$Names <-  gsub(" ", "-", emoji_data$Names)
  
  
  #Adding \\ before a regex functional symbol
  sym <- c("\\$","\\.","\\^","\\*","\\[","\\]","\\?","\\(","\\)")
  sym_replace <- c("\\\\$","\\\\.","\\\\^","\\\\*","\\\\[","\\\\]","\\\\?","\\\\(","\\\\)")
  
  for(i in 1:length(sym)){
    emoji_data$Symbols <- gsub(sym[i],sym_replace[i],emoji_data$Symbols)
  }
  
  emoji_data$Symbols = str_trim(emoji_data$Symbols) #Removing spaces from both ends
  
  return(emoji_data)
}



#========================================================
# Human Emoji Function
#========================================================

#' Human Emojis
#'
#' This function is used to ignore the skin tones and considers all colors as same.
#' @param emoji_data , data frame
#' @examples
#' emoji_human <- emoji_human_color_ignore(emoji_human)
emoji_human_color_ignore <- function(emoji_data)
{
  emoji_data$Names <- gsub(":.*$","",emoji_data$Names) 
  
  return(emoji_data)
}

#========================================================
# Emoji Replacer Function
#========================================================


#' Replace Emoji with name
#'
#' This function replaces all the emojis with their respective names.
#' @param emoji_data , data frame
#' @param text_data , data frame
#' @examples
#' clean_data_without_media_emoji_replaced <- emoji_replacer(emoji_all, clean_data_without_media)
emoji_replacer <- function(emoji_data, text_data)
{
  for(i in seq_len(nrow(emoji_data))){
    clean_data_without_media_temp = gsub(emoji_data[i,2],emoji_data[i,1],text_data[,4])
    text_data$message  = gsub(emoji_data[i,2],emoji_data[i,1],text_data$message)
  }
  return(text_data)
}




#========================================================
# Function to make new column foe each emoji with count
#========================================================

#' Make column with emoji count
#'
#' This function creates new column for each emoji with their count.
#' @param emoji_data , data frame
#' @param text_data , data frame
#' @examples
#' clean_data_without_media_with_emoji <- make_emoji_count_column(emoji_all, clean_data_without_media)
make_emoji_count_column <- function(emoji_data, text_data)
{
  #Creating columns for each emoji with count
  emoji_array <- as.character(emoji_data$Names)
  clean_data_without_media_with_emoji <- text_data
  
  for(i in emoji_array){
    clean_data_without_media_with_emoji[,i] <- str_count(text_data$message,i)
    
  }
  return(clean_data_without_media_with_emoji)
}


#========================================================
# Function get index and to remove emoji columns
#========================================================

#' Remove unused emojis
#'
#' This function removes all emoji columns that have sum equal to zero.
#' @param text_data , data frame
#' @examples
#' clean_data_without_media_with_emoji <- remove_unused_emoji(clean_data_without_media_with_emoji)
remove_unused_emoji <- function(text_data)
{
  unused_emoji_index = c(NA)
  #Getting indexes of unused emojis
  for(i in 6:length(text_data)){
    sum = sum(text_data[,i])
    cat(sprintf("%s = %i \n",names(text_data)[i],sum))
    if(sum == 0)
    {
      unused_emoji_index <-  c(unused_emoji_index,i)
    }
  }
  unused_emoji_index <- unused_emoji_index[-1] 
  length(unused_emoji_index)
  
  #Removing unused emojis
  text_data <- text_data[,-unused_emoji_index]
  
  #Removing emoji- from column names
  names(text_data) <- gsub("^.*?emoji-", "", names(text_data))
  
  return(text_data)
}


