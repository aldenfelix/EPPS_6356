function(input, output){
  #### Input parameters ####
  
  # Input for DESC page PIE
  
    # Select variable for chart
    DescTabVar <- reactive({
      
      # Replace space with . in variable name
      gsub(" ", ".", input$DescRadio)
    })
    
    # Select variable for chart
    DescPieVar <- reactive({
      
      # Replace space with . in variable name
      gsub(" ", ".", input$DescRadio2)
    })
    
    # Select variable for chart
    DescBarVar <- reactive({
      
      # Replace space with . in variable name
      gsub(" ", ".", input$DescRadio3)
    })
    
    
    
  # Input for INF page COEF
    
    #Select which Models to Display
    InfCoefModel <- reactive({
      if ("All" %in% input$InfCoefCheck) {
        c(gsub("Stage ", "", input$InfCoefCheck[1:(length(input$InfCoefCheck)-1)]),"All")
      } else {gsub("Stage ", "", input$InfCoefCheck)}
    })
  
  # Input for INF page PROB
    
    # Select which Models to Display
    InfProbModel <- reactive({
      as.numeric(gsub("Stage ", "", input$InfProbCheck))
    })
    
    # How to Display plots
    InfProbDisplay <- reactive({
      switch(input$InfSortInput,
             "Stage" = c("Stage", "Class"),
             "Class" = c("Class", "Stage"))
    })
    
    # Select which Road classes to Display
    InfClassModel <- reactive({
      sapply(input$InfProbClass, switch,
             "County Road" = 1,
             "City Street" = 2,
             "Farm to Market" = 3,
             "Interstate" = 4,
             "Non-Trafficway" = 5,
             "Other Road" = 6,
             "Tollways" = 7,
             "US & State Highways" = 8)
      
    })
    
    # Input Parameter Transformations
    InfProbInter <- reactive({
      switch(input$InfInterInput,
             "True" = 1,
             "False" = 0)
    })
    
    InfProbTime <- reactive({
      switch(input$InfTimeInput,
             "Morning" = c(0,0,0),
             "Day" = c(1,0,0),
             "Evening" = c(0,1,0),
             "Night" = c(0,0,1))
    })
    
    InfProbWeath <- reactive({
      switch(input$InfWeathInput,
             "Normal" = 0,
             "Dangerous" = 1)
    }) 
    
    InfProbColl <- reactive({
      switch(input$InfCollInput,
             "One Car" = c(0,0,0,0),
             "Angular" = c(1,0,0,0),
             "Opposite" = c(0,1,0,0),
             "Other" = c(0,0,1,0),
             "Same" = c(0,0,0,1))
    })
  
  
  #### Output functions ####
    
  # Desc Page, Descriptive Plot
  FreqTab <- reactive({
    
    # Create a frequency table of Selected Variable
    tab <- table(crash[,DescTabVar()])
    
    tab <- as.data.frame(tab)
    
    colnames(tab) <- c(input$DescRadio, "Frequency")
    
    return(tab)
    
  })
    
   output$FreqPlot <-  renderTable(FreqTab(),
                                  align = "lr", bordered = T, striped = T)
  
  # Desc Page, Pie Plot
    PiePlotFunc <- reactive({
      # Create a pie chart of the Selected Variable
      
      counts <-  crash %>% count(across(DescPieVar()))
      
      pieplot <- plot_ly(data = counts, values = ~n, labels = ~get(DescPieVar()), 
              type = 'pie',
              textposition = 'inside',
              textinfo = 'label+percent', 
              width = 800, height = 800) %>% 
        layout(title = "Makeup of Accident Data by Variable")
      
      return(pieplot)
    })
    
    output$PiePlot <- renderPlotly({
      PiePlotFunc()
    })
    
    
    # Desc Page, Bar Plot
    output$BarPlot <- renderPlotly({
      # Create a Bar Plot of the Selected Variable
      
      factor_data <- data.frame(lapply(crash, factor))
      
      bar_var <- data.frame(factor_data %>% count(across(DescBarVar())))
      
      bar_var <- bar_var %>% 
        mutate(perc = paste0(sprintf("%4.1f", n / sum(n) * 100), "%"))
      
      plot_ly(data = bar_var, x = ~get(DescBarVar()), y = ~n,
              type = "bar", text = ~paste0(sprintf("%4.1f", n / sum(n) * 100), "%"),
              textposition = "outside") %>% 
        layout(xaxis = list(categoryorder = "total ascending", 
                            title = input$DescRadio3),
               yaxis = list(title = "Number of Accidents"),
               title = "Makeup of Accident Data by Variable")
    })
  
  # Inf Page Coefficient Plot
  CoefPlotFunc <- reactive({
    
    # for loop to remove non-selected models through row selection
    seq <- c()
    for (i in as.numeric(InfCoefModel()[InfCoefModel() != "All"])) {
      seq <- c(seq,seq(i,32,4))
    }
    
    # Load saved coefficient matrix from regression results (done separately so the application doesn't have to run the model)
    coeff.mat <- coeff.matrix
    
    # Change the names of the term variable for display reasons
    coeff.mat$term <-  c(rep(c("(Intercept)", "City Street", "Farm to Market", "Interstate", "Non-Trafficway", "Other Road", "Tollways", "US & State Highways"), each = 4), c("Speed Limit", "Dangerous Weather", "Day", "Evening", "Night", "Angle", "Opposite", "Other", "Same", "At Intersection"))
    
    # Add new variable model for dwplot to sort lines by
    coeff.mat$model <- c(rep(c("Stage 1", "Stage 2", "Stage 3", "Stage 4"), times = 8),rep("All Stages", 10))
    
    # Reduce data to just specified models
    coeff.red <- coeff.mat[c(sort(seq),if ("All" %in% InfCoefModel()) {33:42} else {}),]
    
    # Brackets to show variables
    brackets <- if ("All" %in% InfCoefModel()) {
      list(c("Road Class", "City Street", "US & State Highways"),
           c("Time of Day", "Day", "Night"),
           c("Type of Collision", "Angle", "Same"))
    } else {
      list(c("Road Class", "City Street", "US & State Highways"))
    }
  
    #Create the basic Coefficient Plot using the dotwhisker package
    coefplot <- dwplot(coeff.red, 
                       show_intercept = TRUE,
                       vline = geom_vline(
                                          xintercept = 0,
                                          colour = "grey60",
                                          linetype = 2),
                       whisker_args = list(size = 1),
                       dot_args = list(size = 1.5)
                       ) + 
      labs(colour = "Stage", x = "Coefficient", title = "Coefficient Plot") + 
      scale_colour_manual(values = c("#E69F00", "#009E73", "#D55E00", "#0072B2", "#CC79A7")[if ("All" %in% InfCoefModel()) {sort(c(5:1)[c(as.numeric(InfCoefModel()),5)])} else {sort(c(5:1)[as.numeric(InfCoefModel())])} ]) + 
      theme(axis.text.y = element_text(size = 16, family = "serif"),
            axis.title.x = element_text(size = 16, family = "serif"),
            plot.title = element_text(size = 24, family = "serif", face = "bold"),
            legend.text = element_text(size = 16, family = "serif"),
            legend.title = element_text(size = 16, family = "serif"),
            legend.key.size = unit(1, "cm"))
    
    # Create Brackets for categorical variables
    coefplot <- coefplot %>% add_brackets(brackets, fontSize = 1.5)
    
    return(coefplot)
    
  })
  
  output$InfCoefPlot <- renderPlot({
    print(CoefPlotFunc())
  })

  
  output$InfCoefDwn <- downloadHandler(
    # Saving the Probability Plot
    filename = "CoefficientPlot.png",
    content = function(file) {
      png(file, width = 800, height = 1200, units = "px")
      print(CoefPlotFunc())
      dev.off()
    }
  )
  
  # Inf Page Probability Plot
  # Generate the Probability Table
  InfProbTable <- reactive({
    
    # Create a vector of parameters for probability
    probparameter <- c(input$InfSpeedInput,InfProbWeath(),InfProbTime(),InfProbColl(),InfProbInter())
    
    # Create the coefficient matrix to get the log odds
    estmat <- matrix(0, nrow = length(InfProbModel()), ncol = 18)
    for (i in InfProbModel()){
      # This is to allow the for function to properly put values into the estmat matrix
      i2 <- match(i, InfProbModel())
      
      # Just pulling coefficient values from coeff.matrix
      estmat[i2,] <- coeff.matrix$estimate[c(seq(i,32,4),33:42)]
    }
    
    # Create the parameter matrix to get the log odds
    parmat <- matrix(0, nrow = 18, ncol = 8)
    for (i in 1:8){
      
      # Creates a vector for each Road Class with the shiny parameters afterwards
      parmat[,i] <-  c(1,rep(0,max(0,i-2)),ifelse(i == 1,0,1),rep(0,min(6,8-i)),probparameter)
    }
    
    # Create matrix that expresses confidence intervals of predictions
    probci <- matrix(0, nrow = length(InfProbModel()), ncol = 8)
    for (i in InfProbModel()) {
      
      # Describe for parameters
      i2 <- match(i, InfProbModel())
      a <- qt(input$InfAlphInput/200, nrow(crash) - nrow(coeff.matrix), lower.tail = F)
      
      # Creating a varying variance-covariance matrix that depends on which stage we are looking at
      vvc <- vcov[c(seq(i,32,4),33:42),c(seq(i,32,4),33:42)]
      
      # extracting the diagonal values of standard error calculation
      # non-diagonal values are garbage values with no meaning
      probci[i2,] <- sqrt(diag(t(parmat) %*% vvc %*% parmat)) * a
    }
    
    # Create a matrix that is the predicted log odds
    # Rows are models, columns are Road classes
    probest <- estmat %*% parmat
    
    # Transforms log odds into probability using e^y / (e^y + 1) where y is the predicted log odds
    probprob <- exp(probest) / (exp(probest) + 1)
    probupper <-  exp(probest + probci) / (exp(probest + probci) + 1)
    problower <- exp(probest - probci) / (exp(probest - probci) + 1)
    
    # Data frame with all the data combined into a singluar table
    probmodel <- data.frame(
      "Stage" = paste0("Stage ",rep(InfProbModel(), each = length(InfClassModel()))),
      "Class" = rep(c("County Road", "City Street", "Farm to Market", "Interstate", "Non-Trafficway", "Other Road", "Tollways", "US & State Highways")[InfClassModel()], times = length(InfProbModel())),
      "prob" = c(t(probprob[,InfClassModel()])),
      "lower" = c(t(problower[,InfClassModel()])),
      "upper" = c(t(probupper[,InfClassModel()]))
    )
    
    if (input$InfProbInv == T) {probmodel[,3:5] <- 1 - probmodel[,3:5]} else {}
    return(probmodel)
  })
  
  # Probability Plot function
  InfProbPlotFunc <- reactive({
    
    probmodel <- InfProbTable()
    
    # Table that lists values selected
    estest <- data.frame(
      "Variable" = c("Speed Limit", "Weather", "Time of Day", "Type of Collision", "Intersection", "Alpha"),
      "Value" = c(input$InfSpeedInput,input$InfWeathInput,input$InfTimeInput,input$InfCollInput,input$InfInterInput, input$InfAlphInput/100)
    )
    
    # estest as grob
    estest.grob <- tableGrob(estest, rows = NULL,
                             theme = ttheme_default(base_size = 18))
    yname <- ifelse(input$InfProbInv == T, "Probability of Continuing", "Probablity of Stopping")
    
    # Generate ggplot bar plot mapping probability
    plot.base <- ggplot(probmodel, aes(fill = eval(str2lang(InfProbDisplay()[2])), y = prob, x = eval(str2lang(InfProbDisplay()[1]))) ) + 
      geom_bar(position = "dodge", stat = "identity") + 
      geom_errorbar(aes(ymin = lower, ymax = upper), position = position_dodge(.9), width = 0.4, colour = "black") +
      theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1, size = 16, family = "serif"),
            axis.title = element_text(size = 18, family = "serif"),
            axis.text.y = element_text(size = 16, family = "serif"),
            plot.title = element_text(size = 24, family = "serif", face = "bold"),
            legend.title = element_text(size = 18, family = "serif"),
            legend.text = element_text(size = 18, family = "serif"),
            legend.key.size = unit(1, "cm")) + 
      xlab(InfProbDisplay()[1]) + ylab(yname) +
      ggtitle(paste0(if (input$InfProbInv == T) {"Inverted "} else {}, "Probability Representation of Road Class Sorted by ",InfProbDisplay()[1])) + 
      labs(fill = InfProbDisplay()[2]) + 
      scale_fill_manual(values = c("#E69F00", "#56B4E9", "#009E73", "#CC79A7", "#0072B2", "#F0E442", "#D55E00", "#999999")[c(if (input$InfSortInput == "Class") {InfProbModel()} else {InfClassModel()})])
    
    # Nab instructions to build legend
    g_legend <- function(a.gplot){
      tmp <- ggplot_gtable(ggplot_build(plot.base))
      leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
      legend <- tmp$grobs[[leg]]
      return(legend)
    }
    
    # Legend Grob
    legend <- g_legend(plot.base)
    
    # Arrange table under legend
    plot.fin <- grid.arrange(plot.base + theme(legend.position = "none"), 
                             widths=c(3/4, 1/4),
                             arrangeGrob(legend, estest.grob), ncol = 2)
    
    # Return grid instructions (cannot be drawn normally, lookup how to draw it depending on circumstance)
    return(plot.fin)
  })
  
  output$InfProbPlot <- renderPlot({
    # print plot with table grobs
    print(InfProbPlotFunc())
  })
  
  output$InfProbDwn <- downloadHandler(
    # Saving the Probability Plot
    filename = "ProbabilityPlot.png",
    content = function(file) {
      png(file, width = 1200, height = 800, units = "px")
      grid.draw(InfProbPlotFunc())
      dev.off()
    }
  )
  
}