;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Created by: El-Hachemi Kadri                                                      ;;
;; Under the supervision of Professor Babak Esfandiari                               ;;
;;                                                                                   ;;
;;                                                                                   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; component of the network
breed [ peers peer]
breed [documents doc]

directed-link-breed [follow-links follow-link]
directed-link-breed [document-links document-link]


globals [
  num-peers
  num-docs
  max-docs-stored                    ;;maximum of liked documents for each peer at the start of the simulation
  list-labels
  my-docs
  number-labels                      ;;number of labels
  maxStayConnected                   ;;maxium time for a peer to stay connected
  minStayConnected                   ;;minimum time for a peer to stay connected
  maxStayDisconnected                ;;maxium time for a peer to stay disconnected
  minStayDisconnected                ;;minimum time for a peer to stay disconnected
  maxTicks                           ;;for how long the simulation runs
  failureThreshold                   ;;how many consecutive  failures (non-hits means that the score doesn't go up) until a peer decides to changes his strategy
  minFriends                         ;;minimum number of friends that a peer can have - default is 0, but you can change the variable in the set-variables procedure
  strategies                         ;;global variable that holds all the strategies for ranking documents
  numFriendFollowers                 ;;number of friend followers
  numCrowdFollowers                  ;;number of crowd followers
  numAttackers                       ;;number of attackers
  crowdColor
  fFollowerColor
  attackerColor
  randomColor
  
]

peers-own
[ 
  ttl
  connected?
  timeDisconnected
  number-docs
  nhood
  taste
  number-friends
  peer-behavior
  peer-strategy                     ;;holds the metric that the peer is using for ranking documents
  peer-similarity                   ;;variable to hold similarity of the peers to the active peer in each iteration
  failureCount                      ;; count how many times a stratedy failed to give us new results
  lastResult                        ;; keep track of last results
  score
  oldScores                         ;; list of previous scores 
  changeStrategy                    ;;count how many times a peer has changed his strategy
  population                        ;;shows what population the peer is in
]

documents-own
[
  isstored?
  tag
  scoreDoc
  
]
document-links-own
[
 stored?
]


__includes ["set_variables.nls"]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  SETUP PROCEDURE: clears simulation, and resets ticks  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to setup
 if ( random-seed? ) [
  random-seed the-random-seed 
  ]
  clear-all
  set-variables
  type "A network of " type num-peers type " peers and " type num-docs print " documents"
  make-peers num-peers  ;; creating the peers
  make-documents num-docs  ;; creating documents
  make-friends   ;; making friends links between peers
  if not default? [  make-populations ] ;; create the populations if the default switch is OFF (default)
  add-documents peers documents  
  ;ask peers [ calculate-score [self] of out-document-link-neighbors ]   ;;calculate initial score
  ask patches[ set-separation ]  ;;create the separation between the two groupes, peers and documents
 
  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;                                 MAIN PROCEDURES                                               ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go                                         ;;main procedure for running the simulation
  if (count document-links = count peers * count documents) and (stop?) [ 
    user-message "All documents are liked by all the peers, no more possible iterations!"   ;; stop simulation if all documents are liked by all peers
    stop       
    ]
  if dynamic-network? [ dynamic-network-update ]              ;; enable peers disconnecting and connecting to the network
  let active-peer one-of peers                                ;; select a peer for the iteration
  ask active-peer [ do-actions ]                              ;; the peer executes all the actions necessary (download, rank, like, and calculate score)
  produce active-peer                                         ;; peer produces a document
  tick
  if ticks > maxTicks and stop? [ stop ]
  
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;                                 THE PROCEDURES                                                ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;           these are the procedures for creating peers and documents and links                     ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to make-peers [num]                           ;; creating the nodes representing the users of the network

  create-peers num[
    set ttl 80 + random maximum-life                   ;; setting the ttl for the peer 
    set xcor max-pxcor / -2
    set ycor random (max-pycor - 1)
    fd random 10
    set size 1.2    
    set taste n-of (1 + random 3) list-labels          ;; set number of taste (here it's minimum of 1 and maximum of 3)
    set label word "  " who
    set label-color black + 1
;    ifelse taste = "red" [ set color red  ]
;    [ifelse taste = "yellow" [ set color yellow ] 
;    [ifelse taste = "green" [ set color green] 
;    [ ;;default
;      set label-color black 
;      
;     ]]]
    set color blue + 2
    if default? [ set peer-strategy ranking-metric ]    ;; choose default metric at the start for all the peers
    set number-docs 0                                   ;; they have yet to like documents
    set number-friends 0
    setxy 0.99 * xcor 0.99 * ycor 
    move-turtles "not any? other turtles-here and pxcor < 0"
    ;add-color taste
    set score 0                                         ;; all peers start initially with a score of 0, they still haven't liked any documents yet
    set oldScores []                                     ;; makes sense because we don't yet have scores for the peers
    set failureCount 0
    set changeStrategy 0
    set failureCount 0
    set timeDisconnected 0  
    set connected? true                            ;; all the peers start connected, so this makes sense
    disperse
    ]
end

to make-documents [num]           ;; creating the documents of the network
  create-documents num [
    set xcor max-pxcor / 2
    set ycor random (max-pycor - 1)
    fd random 10
    set size 1.4 
    set label who
    set label-color black
    setxy 0.99 * xcor 0.99 * ycor 
    set isstored? false
    set tag n-of (1 + random 3) list-labels                 ;; documents have multiple tags (here it's min 1 and max 3)
    add-color tag
    move-turtles "not any? other turtles-here and pxcor > 1"
     
    ]

end

to produce [p]                    ;; procedure to produce new documents
  if produce? [
    let i random-float 100
    if produce-chance >= i [
    create-documents 1 [
    set xcor max-pxcor / 2
    set ycor random (max-pycor - 1)
    fd random 10
    set size 1.4 
    set label who
    set label-color black
    setxy 0.99 * xcor 0.99 * ycor 
    set isstored? false
    set tag n-of ((random length [taste] of p) + 1) [taste] of p           ;;affect randomly n labels of the peer taste to the tags of the new document
    add-color tag  ;;for spreading the documents
    move-turtles "not any? other turtles-here and pxcor > 1"
    create-document-link-from p [set color brown + 1.5]
    ]    
  ]
  ]
  
end

to add-documents [ peer doc ]                                        ;;affects documents to a peer's repository (initial liked documents), this is for the setup phase at the start of the simulation
    
  ask peer [ 
    let n random count doc  
    while [doc != nobody and n > 0 and number-docs < max-docs-stored] [ 
      create-document-link-to one-of doc [set stored? true set color gray + 2 ask other-end [ set isstored? true ]] set number-docs number-docs + 1 set n n - 1
      ] 
    ]
 
end

to make-friends             ;; creates friendship between peers randomly in the network
  
ask peers [                 ;;each peer creates random friendship links with other peers with maximum of max-peers and minimum of 0
   set nhood n-of (random (max-friends + 1) + minFriends) other peers   ;; select a random number of friends
   let friendcolor [ green ]  
   if count nhood != 0 [ create-follow-links-to nhood [ set color one-of friendcolor ] 
   set number-friends number-friends + 1 ]
 ]
  
end

to make-populations                                          ;;procedure to create the heteregeneous populations  
  set numCrowdFollowers round((num-peers * crowd-followers) / 100)
  set numFriendFollowers round((num-peers * friend-followers) / 100)
  set numAttackers round((num-peers * attackers) / 100)
  
  type "We have " type numCrowdFollowers print " crowd followers"
  type "We have " type numFriendFollowers print " friend followers"
  type "And " type numAttackers print " attackers"
    
  let k shuffle (sort peers)                                ;;make a random shuffled list of peers 
  ;; extracting peers from the list following the number of each population  ;;
  let tempCF sublist k 0 numCrowdFollowers
  let tempFF sublist k numCrowdFollowers (numCrowdFollowers + numFriendFollowers)
  let tempAT sublist k (length k - numAttackers) length k 
  ;; now affecting the peers to their respective populations  ;;
  foreach tempCF [ ask ? [ set population "crowd follower" set peer-strategy "document popularity" set color crowdColor]  ]    ;; choose ranking metrics for the population to use
  foreach tempFF [ ask ? [ set population "friend follower" set peer-strategy "peer similarity" set color fFollowerColor] ]
  foreach tempAT [ ask ? [ set population "attacker" set peer-strategy one-of strategies  set color attackerColor] ]               ;; choose a random ranking metric for the malicious peers,
                                                                                                          ;; this can be improved, e.g. creating a different ranking metrics for malicious peers (attackers)  
end


;to-report dl-documents ;; report list of documents returned to a peer for the download
;  ask peers [ set color blue + 2 set size 1.2 ]
;  set size 2
;  set color cyan + 2
;  let p out-link-neighbors ;with [ number-docs > 0]   ;; take only the friends that have documents in their repository
; 
;  ask p [ set color orange] ;; change the color of the friends of the active peer
;  let k p with [ out-document-link-neighbors != [] ]
;  let docs-downloaded [out-document-link-neighbors] of k
;  let D [out-document-link-neighbors] of k
;  set D filter is-agentset? D
;  create-document-links-to D
;  if docs-downloaded != [] [
;  ;create-document-links-with docs-downloaded 
;  ]
;  report [ [who] of out-document-link-neighbors ] of p   ;; reports the labels of the documents i.e the who number
;  ;; report [ docs-stored ] of p  ;; reports the documents of all the friends and puts thems in a list of agentsets
;
;end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;                                  THE FUNCTIONS                                                ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report list-of-documents [metric] ;; report list of documents returned to a peer after the ranking 
  let dc documents
  let listlabel (list)
  if metric = "peer taste" [
      set dc sort-by [ [tag] of ? = taste] dc
      report dc
  ]
  if metric = "peer similarity" [
      let p self
      let k [self] of other peers with [connected?]     ;;take only the connected peers (doesn't make a difference if dynamic_network isn't activated)
      let winner nobody
      if (k != nobody and k != []) [            
      foreach k [ 
          let s similarity p ?        
          ask ? [set peer-similarity s]
;;        ask ? [ type ? type " " print peer-similarity]    printing the peer similarity between the peers and active peer
          
          ]
      ]
      set k sort-by [([peer-similarity] of ?1) > ([peer-similarity] of ?2 )] k
      let doc-winner []
      
;      show k 
;      foreach k [ ask ? [show taste] ]    ;;show the taste of the other peers
            
      if k != [] [                         ;; rank the list from the higher similarity (p,pi) to the lowest
        set k reverse k
        set winner last k
        set dc [self] of documents
        foreach dc [ ask ? [ 
                ifelse (count in-document-link-neighbors != 0) [
                let owners in-document-link-neighbors        ;; select the peers who like the document
                ;show word "the owners are : " [self] of owners                    
                let max-score max [peer-similarity] of owners 
                if verbose? [ show word "MAX PEER SIM " max [peer-similarity] of owners ]
                set scoreDoc max-score + 1
                               
               ] [ 
               set scoreDoc 0
               ]
               if verbose? [ show word "Score for doc:" scoreDoc]
        ]          
            ]
        
        foreach k [
          let d sort [out-document-link-neighbors] of ?   ;; sort documents from documents of the most popular to documents of the least popular peer
          if d != []
          [
            set dc remove-duplicates sentence d dc
          ]
        ]
        ]   
      if verbose? [ show word "dc list before ranking " dc ]
      set dc sort-by [[scoreDoc] of ?1 > [scoreDoc] of ?2] dc      ;;sort documents by their score
      if verbose? [ show word "dc list after ranking  " dc ]
  
                
      if verbose? [ show word "most similar peer : " winner ]
     report dc
     
      
      
  ]
  
   if metric = "peer popularity" [
      let pp sort-on [ (- count my-in-follow-links)] peers with [connected?]  ;; sort the list of peers by counting the number of follower from the most popular to the least
      let pop-peer first pp
      let pop-peer-docs [self] of [out-document-link-neighbors] of pop-peer
      ;; rank the popular peers and filter those with no documents
      if (popular-p-filter?) [
          if pop-peer = self     ;; if the popular peer is the active peer then remove it from the list
          [      
            set pp but-first pp
            ]
          if pop-peer-docs = []   ;; if the popular peer dosen't have any documents then remove it from the list
          [
            set pp but-first pp
            ]
      ]
      set pop-peer first pp
      ;;
      if verbose? [ show word "popular peer: " pop-peer ]
      if verbose? [ show word"documents of popular peers :" pop-peer-docs ]
      let doc-pop [out-document-link-neighbors] of pop-peer
      set dc sort-by [  member? ? doc-pop ] dc
      report dc
  ]
   
  if metric = "document similarity" [
      ask out-document-link-neighbors [ set listlabel fput tag listlabel]
      set dc sort-by [ member? [tag] of ? listlabel] dc
      report dc
  ]
  
;  if metric = "friends similarity" [
;      let k out-follow-link-neighbors with [ out-document-link-neighbors != [] ]
;      ask k [ ask out-document-link-neighbors [ set listlabel fput tag listlabel ]
;        show word "list-label = " listlabel]
;      set dc sort-by [ member? [tag] of ? listlabel] dc
;      report dc
;  ]
  if metric = "document popularity" [                           
      set dc sort-on [ ( - count my-in-document-links )] dc                 ;; rank documents by their popularity (number of likes)
      report dc
  ]
  
  
    ;; reports the labels of the documents i.e the who number
  ;; report [ docs-stored ] of p  ;; reports the documents of all the friends and puts thems in a list of agentsets

end

to-report similarity [ p1 p2]  ;;peer procedure to calculate the similarity between two peers
    let sim1 [self] of documents with [ (in-document-link-neighbor? p1) and (in-document-link-neighbor? p2)]   ;; select documents shared between the two peers
    set sim1 remove-duplicates sim1                                              ;; remove possible duplicates in the list
    let card1 length sim1
    let sim2 [self] of [out-document-link-neighbors] of p2                      ;; list of documents that p2 likes
    let liked [self] of [out-document-link-neighbors] of p1                     ;; list of documents that p1 likes
    set sim2 sentence sim2 liked                                                ;; merging the two lists so we have the list of liked document by the two peers
    set sim2 remove-duplicates sim2                                              
    let card2 length sim2
   report ifelse-value (card2 != 0) [ card1 / card2] [ 0 ]                      ;;calculate peer-similarity and report it   
  
end

to do-actions                                ;; peer procedure: it's the main procedure used by the active peer for downloading then ranking, and liking documents
  highlight-peers
  let doc-list list-of-documents peer-strategy
  if verbose? [  show word "The  ranked  list is:" doc-list ]
  set my-docs [self] of (out-document-link-neighbors)
  if is-agentset? doc-list [ set doc-list [self] of doc-list ]
  ;set my-docs sort-on [ ( - count my-out-document-links )] my-docs 
  ;set my-docs sort-by [ ([count my-in-document-links] of ?1) >  ([count my-in-document-links] of ?2) ] my-docs
  if (filter-list?) [            ;;filtering the liked documents
    foreach my-docs [
  set doc-list remove ? doc-list ]
  if verbose? [ show word "Filtered ranked list:" doc-list ]
  ] 
  
  ifelse length doc-list != 0 [
  ifelse length doc-list >= top-k [
    ifelse doc-list != [] and behavior = "good"[
    set doc-list behavior-action "good" doc-list
      ]
      [ if behavior = "bad" [
           set doc-list behavior-action "bad" doc-list
                   ]
            ]
      if behavior = "random" [
        let random-behavior one-of ["good" "bad"]
        set peer-behavior random-behavior
        set doc-list behavior-action peer-behavior doc-list       
        
      ]
      
      ]
    [ 
   if doc-list != [] [
    if verbose? [ show word "liked documents" doc-list ] 
    foreach doc-list [ create-document-link-to ? [ set color black - 2 ]]
        ]
    ]
    
    ifelse (score-metric = "Hachemi Score")[ 
    calculate-score doc-list   
    ][
    calculate-score-babak doc-list   
    ]
    set oldScores fput score oldScores                            ;; update the list of old scores
    if length oldScores > failureThreshold and adapt?[            ;; if we have enough elements in the list and the adaptation is enabled 
       set oldScores sublist oldScores 1 (failureThreshold + 1)   ;; take only the newest k scores
       if (oldScores = n-values failureThreshold [score])  [                                    ;; we test if the strategy isn't giving us good results we will change the strategy after a number of failures
         set failureCount failureCount + 1                        ;; increment number of failures
         show "WOOOOOOOOOOOOOPPPPPPPPPSSSSSSSSSSSSSSSSIIIIIIIIIIIIIIIIIIIIIIIIIIIII"
         let newStrategies remove peer-strategy strategies        ;; remove the strategy from the possible new strategies
         choose-strategy one-of strategies                      ;; choose one of the new strategies
      
       ] 
    ]
  ]   
  [
    if verbose? [ show word "The score is: " score]
    if verbose? [ show "No more possible documents to like!"]
  ]
 
end

to-report behavior-action [behav l]    ;;procedure for random behavior
 ifelse behav = "good"[
   ifelse like-behavior = "standard" [  ;;like all documents in top-k
    set l sublist l 0 top-k
    if verbose? [ show word "liked documents: " l ]
    foreach l [ create-document-link-to ? [ set color black - 2 ]]
      ] 
   [           ;; like only the documents that match the taste      
      set l sublist l 0 top-k
      if verbose? [ show word "Top-K documents: " l ]
      ifelse (like-behavior = "relevant") [
      foreach l [ if (member? [tag] of ? taste) [ create-document-link-to ? [ set color black - 2 ]  
          if verbose? [ show word "likes: " ? ]
          ] ]
      let i 0
      let j 0
      while [i < length l] [
        if [tag] of item i l != taste [  
            set j j + 1
          ]
        set i i + 1
      ]
      if j = i [
       if verbose? [ show word "No documents in top-k match the taste of: " self ]
      ]
      ][      ;; like only the documents that don't match the taste
      let temp-list []   
      foreach l [ if ([tag] of ? != taste) [  create-document-link-to ? [ set color black - 2 ]  
          set temp-list lput ? temp-list
          if verbose? [ show word "likes: " ? ]
          ] ]
          set l temp-list
      ]          
      
      ]
 ]
      [ if behav = "bad" [ 
          ifelse like-behavior = "standard" [ ;;like all documents in top-k         
           set l reverse l
           set l sublist l 0 top-k
           if verbose? [ show word "liked documents (min-k): " l ]
           foreach l [ create-document-link-to ? [ set color black - 2 ]]
      ]
      [                            
           set l reverse l
           set l sublist l 0 top-k
           show word "Min-K: " l 
           ifelse (like-behavior = "relevant") [ ;;relevant behavior which is liking the hits in top-k 
           foreach l [ if ([tag] of ? = taste) [ create-document-link-to ? [ set color black - 2 ]
                if verbose? [ show word "likes: " ? ]
                ] ]
           ][    ;;behavior for liking the misses in top-k 
           let temp-list [] 
           foreach l [ if ([tag] of ? != taste) [ create-document-link-to ? [ set color black - 2 ]
                set temp-list lput ? temp-list
                if verbose? [ show word "likes: " ? ]
            ] ] 
           set l temp-list          
           ]
           let i 0
           let j 0
           while [i < length l] [
             if [tag] of item i l != taste [
               set j j + 1
               ]
             set i i + 1
             ]
           if j = i [
             show word "No documents in top-k match the taste of: " self 
             ]
           ]
      ]      
            ]
      report l
end


to calculate-score [ranked-list]   ;;procedure for calculating the score for the active peer using Hachemi's method
    foreach ranked-list [
      type "the tag of doc " type ? type "is " print [tag] of ?
      show word " the taste of the peer is:" taste
      let tempTaste taste
      let tempTag [tag] of ?
      let result reduce [ ifelse-value (member? ?2 tempTaste) [ ?1 + 1] [ ?1 ] ] (fput 0 tempTag)     ;;result here is the number of labels shared betwenn a peer and a document 
   ifelse (result >= 1) [                  ;; to increase the score we count the hits, in this case for a document to be considered a hit it has to share at least one label (tag) with the the peer (taste)
     set score score + result
     
      ]
    [
      set score score - (1 / length ranked-list)       ;; if we don't have hits in the top-K we decrease the score, 
                                                     ;; note here that this utility function is arbitrary and can be replaced by a more significant and meaningful one
      show "EXECUTED!!!!"
      show ranked-list
      
      ]
    if score < 0 [ set score 0 ]                     ;; normalize score at 0 so it doesn't go bellow it (this might be change in future)
  ]
  if verbose? [ show word "The score is: " score ]
  
end

to calculate-score-babak [ranked-list]   ;;procedure for calculating the score for the active peer using Babak's method 
  if verbose? [ show word "Past score: " score ]
  foreach ranked-list [
   if (member? [tag] of ? taste) and (not member? ? my-docs) [       ;;filtering the documents I already like from contributing to the calculation of the score
     set score score + 1
           ]
  ]
  
   if verbose? [ show word "The score is: " score ]
  
end

to-report count-documents
 let d documents with [ (count  my-out-document-links with [not hidden?]) != 0]
 ;show word " the total of hosted documents is: " count d
 report count d
 
 ;show count peers with [ count my-out-follow-links with [ hidden?] != 0 ]
end

to highlight-peers
  ;ask peers [ ifelse taste = "RED" [set color red + 1.5 ][set color yellow + 3] set size 1.2 ]
  ask peers [ choose-color set size 1.2 ]      ;;reset the original sizes and colors
  set size 2.5
  set color color + 1.2
  let p out-follow-link-neighbors                    ;; highlight the friends of the active peer
  ask p [ set size size + 0.4 set color color - 1.5] ;; highlight the friends of the active peer
end

;;;;;;;;;;;;;;;;;;;;;;;;
;;   LAY-OUT & SYLE   ;;
;;;;;;;;;;;;;;;;;;;;;;;;

to add-color [c]        ;; color the document according to the tag
  ifelse c = "RED" 
    [  set color red + 1]
    [  set color yellow ]   
end

to change-layout        ;; turtles procedure to make the network look prettier 
   repeat 50
  [
    layout-spring peers follow-links 0.3 (world-width / (sqrt num-peers)) 0.5
    display
  ]
end


to set-separation      ;; create the visual separation between the peers and the documents
  ifelse (pxcor = 0) [ set pcolor white - 2 ] [ set pcolor white - .3 ]
end

to move-turtles [x]    ;;turtle procedure for the dispersion
  
   ifelse count documents <= 250 [
   while [ any? turtles in-radius 2 with [self != myself] ]   ;;for spreading the documents
    [ move-to one-of patches with [runresult x ] ]
  ][
    while [ any? turtles in-radius 1.4 with [self != myself] ]   
    [ move-to one-of patches with [ runresult x ] ]
  ]
  
end

to disperse           ;; put some distance between the peers so they don't overlap with each other
  if (any? other turtles in-radius 3) [
  move-to one-of patch-set [neighbors] of neighbors
  ]
   
end

;;;;;;;;;;;;;;;;;;;;;;;
;;  Dymanic Network  ;;
;;;;;;;;;;;;;;;;;;;;;;;

to dynamic-network-update  ;; procedure to updating the connecting and disconneting peers
 
 ask peers with [ ttl > 0 ] [ set ttl ttl - 1]
 ask peers with [not connected? and timeDisconnected > 0] [set timeDisconnected timeDisconnected - 1]
 disconnect
 join-network
 
end

to disconnect           ;; peers procedure: disconnecting a peer when ttl reaches 0
 ; let node0 one-of peers with 
 let disconneting-peers peers with [ ttl = 0 and connected? ]
 ask disconneting-peers [ ask my-links [ hide-link ]
   set timeDisconnected (minStayDisconnected + random maxStayDisconnected)
   set connected? false
;   hide-turtle             ;;hide the turtle from view completly (uncomment both this line and the show-turtle line if you want this option)
   
   ]
  
end

to join-network    ;;peer procedure: join the network depending on join-probability value
  let peer-joiners peers with [ timeDisconnected = 0 and not connected? ]  ;;select the peers that have reached the limit for disconnecting so they can join the network again
  
  if peer-joiners != [] and peer-joiners != nobody [
  ask peer-joiners [
      ask my-links [ show-link ]
      set ttl minStayConnected + random maxStayConnected
      set connected? true
;      show-turtle          ;;show turtle again (uncomment both this line and the hide-turtle line in procedure disconnect if you want this option)
      ]
  ]
end

to choose-strategy [strategy]
  ifelse strategy = "document popularity" [
  set population "crowd follower" set peer-strategy strategy set color crowdColor  
  ]    ;; choose ranking metrics for the population to use
  [ ifelse strategy = "peer similarity" [
  set population "friend follower" set peer-strategy strategy set color fFollowerColor 
  ][
  set population "random behavior" set peer-strategy strategy  set color randomColor]
  ]              
                                                                                                            ;; this can be improved, e.g. creating a different ranking metrics for malicious peers (attackers)  
end

to choose-color
   ifelse population = "attacker" [ set color attackerColor ]
    [ ifelse population = "crowd follower" [ set color crowdColor ] 
      [ ifelse population = "friend follower" [ set color fFollowerColor]
        [ set color randomColor ]
      ]      
    ]
  
end

to showpop
  show count peers with [ population = "crowd follower" ]
  show count peers with [ population = "friend follower"]
  show count peers with [ population = "attacker"]
  show count peers with [ population = "random behavior"]
  
  
end  
  


;;;;;;;;;;;
;; TO-DO ;;
;;;;;;;;;;;








@#$#@#$#@
GRAPHICS-WINDOW
351
10
910
590
30
30
9.0
1
10
1
1
1
0
0
0
1
-30
30
-30
30
0
0
1
ticks
30.0

BUTTON
23
249
92
282
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
8
162
175
195
maximum-life
maximum-life
0
80
36
1
1
NIL
HORIZONTAL

SWITCH
9
201
167
234
dynamic-network?
dynamic-network?
1
1
-1000

BUTTON
24
292
93
325
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
24
336
91
369
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
135
458
335
608
AVG Number Friends
Peers
NIL
0.0
20.0
0.0
20.0
true
false
";set-plot-y-range 0 ( num-peers * max-friends - sum [number-friends] of peers with [ (count  my-out-friends-links with [not hidden?]) != 0])\n\n;set-plot-y-range 0 precision (sum [number-friends] of peers with [ (count  my-out-friends-links with [not hidden?]) != 0] / num-peers) 3\n;let s precision (sum [number-friends] of peers with [ (count  my-out-friends-links with [not hidden?]) != 0] / num-peers) 3" ""
PENS
"default" 1.0 0 -8990512 true "" "plot sum [number-friends] of peers with [ (count  my-out-follow-links with [not hidden?]) != 0] / count peers"

BUTTON
10
406
162
439
NIL
change-layout
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
7
123
178
156
max-friends
max-friends
1
5
2
1
1
NIL
HORIZONTAL

MONITOR
1128
293
1249
338
Peers w/o followers
count peers with [ count my-in-follow-links = 0 ]
17
1
11

SWITCH
191
123
330
156
random-seed?
random-seed?
1
1
-1000

INPUTBOX
203
57
314
117
the-random-seed
577
1
0
Number

MONITOR
229
406
321
451
AVG friends
precision (( sum [number-friends] of peers with [ (count  my-out-follow-links with [not hidden?]) != 0]) / count peers) 3
17
1
11

PLOT
920
252
1120
402
Documents liked degree
time
degree likes
0.0
10.0
0.0
10.0
true
false
"set-plot-y-range  0 1" "set-plot-y-range  0 1"
PENS
"nodes-degree" 1.0 1 -16777216 true "" ";plot (count documents-links / count documents)\n\nplot mean [count in-document-link-neighbors] of documents / count peers"

CHOOSER
916
10
1054
55
behavior
behavior
"good" "bad" "random"
0

CHOOSER
915
60
1107
105
ranking-metric
ranking-metric
"peer taste" "peer similarity" "peer popularity" "document similarity" "document popularity"
1

MONITOR
1129
347
1248
392
Peers w/o friends
count peers with [ count my-out-follow-links = 0]
17
1
11

SLIDER
196
164
329
197
top-k
top-k
0
10
2
1
1
NIL
HORIZONTAL

PLOT
931
423
1131
573
plot 1
NIL
NIL
0.0
10.0
0.0
2.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "set-plot-x-range 0 num-peers + 1\nset-plot-y-range 0 2\nset-histogram-num-bars num-peers" "histogram [ peer-similarity] of peers"

MONITOR
14
444
123
489
average score
mean [score] of peers
17
1
11

PLOT
133
247
333
397
Avg Score
Score
Time
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"Score" 1.0 0 -16777216 true "set-plot-x-range 0 100\nset-plot-y-range 0 1" "if ticks mod 5 = 0 [plot mean [score] of peers with [count out-follow-link-neighbors > 0]]"

CHOOSER
1074
10
1238
55
score-metric
score-metric
"Babak Score" "Hachemi Score"
1

SWITCH
1124
63
1238
96
filter-list?
filter-list?
1
1
-1000

SWITCH
1118
112
1245
145
popular-p-filter?
popular-p-filter?
0
1
-1000

CHOOSER
918
112
1022
157
like-behavior
like-behavior
"standard" "relevant" "like miss"
0

SWITCH
1132
165
1239
198
produce?
produce?
1
1
-1000

SLIDER
919
162
1103
195
produce-chance
produce-chance
0
100
30.23
0.01
1
%
HORIZONTAL

SWITCH
1133
211
1239
244
follow?
follow?
1
1
-1000

SWITCH
922
211
1012
244
stop?
stop?
1
1
-1000

SWITCH
1126
255
1246
288
doc-score?
doc-score?
0
1
-1000

SWITCH
13
371
113
404
Verbose?
Verbose?
1
1
-1000

SLIDER
10
10
182
43
crowd-followers
crowd-followers
0
100
57
1
1
%
HORIZONTAL

SLIDER
10
45
182
78
friend-followers
friend-followers
0
100 - crowd-followers
33
1
1
%
HORIZONTAL

SLIDER
9
85
181
118
attackers
attackers
0
100 - crowd-followers - friend-followers
10
1
1
%
HORIZONTAL

SWITCH
208
10
298
43
default?
default?
1
1
-1000

SWITCH
1024
113
1114
146
adapt?
adapt?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

This is a simulation of a social sharing network. In the network we have different peers and documents. The peers can follow each others, and they can like documents too following certain metrics. The trick here is that every peer is potentially different from another one, that means two peers can have a different taste in documents, so they will tend to like different types of documents (documents are not similar too because they can have different labels). In our simulation we have introduced labels. The labels are a generic way of saying that a peer like something, or a document is about this thing. The peer taste is constructed from these labels (he can have one or many labels), as it is the case for documents too, we decided to call the labels for documents tags, but that dosn't stand for the literary tags as in keywords, what we mean by labels here is something more truthful than a tag or a keyword, as in the real world, these can't always describe a document. So in order to decide if some document is relevant to a peer, we use these labels to mesure relevance and calculate the pay-off for the peers. 

## HOW IT WORKS

In the beginning we start with a network of N peers and M documents (N and M chosen by the user) generated at a uniform random distribution. Some peers will have friends (they follow them) at random, and like some documents at random too, this depends on some global variables too, like the maximum number of liked documents, and maximum number of friends (these variables are only relevant at the beginning, because as we run the simulation there will be no limitation to the number of liked documents or friends). Because of this there might be some isolated peers (no followers or friends), and isolated documents. But that's not a problem because we want to see what happens to these isolated nodes as the simulation is running.

## HOW TO USE IT

Before running the simulation the user must click on the set-up button to set the network for the first time.
First you have to pay attention to the python file that comes with the simulation, it will generate the global variable for the size of the network (although we can use sliders for that, but we discarded of them to make the GUI less cluttered).

The user can choose among the different metrics for ranking documents, and behaviors for the peers. The ranking metrics are the stategies used to rank the documents (peer similarity, document popularity, etc), and the peer behavior, is the behavior of the peer toward the list of ranked documents, will he like the top K documents (good behavior), or rather choose from the bottom of the list min K (bad behavior), or it can be chosen at random (ramdom behavior).

Like behavior: 
- standard: this is the behavior of the peer if he will like the top K regardless of the similarity in labels or not.
- relevant: the peer will only like the documents that he finds relevant to him.
- like miss: the peer will only like the miss in the top K (this behavior is relevant if we have a different type of peers and they have a different utility function for calculating their score, e.g. malicious peers)

You will notice in the GUI sliders for choosing populations, these are used to make use of predefined profiles for the peers: what this means, is for example is we have 40 peers and the user chose 50% of "Crowd Followers", we will end up with 20 peers that are crowd followers, i.e. use the same metric (document popularity) and have the same behavior.

The profiles make use of the ranking metrics:
- The crowd followers use document popularity.
- The friend followers use peer similarity.
- The attackers for now use a random strategy (each one of them picks a strategy at random) as their goal is not liking documents but distribuing their files in the network.

We have the switch "dynamic_network" which if set at ON, will enable peers to join and disconnect from the network, it's important to note that a disconnected peer cut off all connexion, and then when he's online again he restores them.

The button step runs the simulation for one tick.

The button go runs the simulation until the user stops it or it stops by itself if the user definer a limit of ticks (using the python script) and the switch "stop?" is set to ON.

"Verbose?" is useful if the user want to see the output on the console (although it can make the simulation slower depending on the size of the network).

"filter-list?" if is set ON, the ranked list will be filtered, and the peer will only get document he doesn't already like in the final ranked list, otherwise without the filtering he will get the list as is.

We have implemented two utility functions (score-metrics) to calculate the score for the peers. Both functions increment the score for a peer when he gets a hit in the top K, the difference between the two, is that one (Hachemi-score) decrements the score when there is a miss in the top K, and the other one (Babak-score) dosen't.

"popular-p-filter?" is used to filter out popular peers without documents, or in the case that active peer is the most popular one, so he dosen't figure in the list of peers.

"follow?" activates the follow system, the peers will follow new peers according to a function.


## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

This model is surely not complete, and there are different ways to extend it: adding new metrics for ranking, adding new behaviors, than means new population of peers (e.g. some ideas, anti-social peers: peers that don't follow anyone, advertiser peers: peers that want other peers to like their documents and have a different utility function for calculating their score).

There are also some improvements to be made in regards of the current code, we would like to optimize the code so it runs faster, for example instead of going through all the peers, we can choose a new efficient method for selecting just a few, or maybe filtering peers that are too far on the graph (distant neighbors) or are not reachable.

## NETLOGO FEATURES

We have made extensive use of lists and and features of agents and agentsets, especially for ranking and filtering.

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

slim-link
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 120 180
Line -7500403 true 150 150 180 180

@#$#@#$#@
0
@#$#@#$#@
