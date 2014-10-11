//
//  AFHTTPRequestOperationManagerFailover.h
//  Talk
//
//  Created by Dev on 9/9/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//
//staWill your component meet the following (global) requirements:
//- No changes are made to AFNetworking; only existing AFNetworking hooks/delegates/methods are used.
//Nick: yes
//- My code using AFNetworking won’t notice anything from the DNS querying and retries. (Except of course when retrying did not result in finding a good server.)
//Nick: yes
//- The component has a delegate property that can be set by my code. The delegate protocol has only one method: - (BOOL)checkReplyContent:(id)content. The component calls this method for each succesful reply received, passing it the deserialized JSON reply body (AFNetworking does this deserialization automatically). When this method returns NO, the component should handle this as if the server is down. This feature is to allow my code to tell the component about internal server errors, which I described during our Skype chat.
//Nick: sounds good
//- The component must add a very low network load. And, the component must not do any network access, when the app is not using AFNetworking.
//Nick: yes
//- The component must use its own thread(s), and may not block main thread or AFNetworking. I mean, there must be an appropriate threading model.
//Nick: yes
//- The component should be able to handle many (let’s say 10 - 20) servers without any problem or severe loss of performance.
//Nick: yes
//- The component may not cache the SRV records on disk. (But of course some caching in memory may be appropriate.)
//Nick: yes
//- The component should be extremely robust against loss of network and all other real-life situation.
//Nick: yes
//- Reachability info should not be considered to be 100% correct; the component for example may not wait when reachability says there’s no internet connection.
//- I have my own reachability manager, which also gives info about being behind a Wi-Fi captive portal (I don’t know if AFNetworking does that). It should be simple to use that one. But I guess it will never be hard to replace one with the other as the API is simple & small.
//Nick: Sounds good, how about we use your own implementation of reachability menager? We will consider easy replacement with the standard ones.
//It does not matter which one we use, none of them may be considered to give a 100% accurate status. In what way do you intend to use the reachability status and/or notifications?
//
//- The component should be able to handle multiple concurrent requests. It’s quite normal that our app first gets a list of UUIDs via one API, and once that result comes back immediately fires off a request to get the details of each object per UUID.
//
//- The component should have a clear structure without uncessary layers/abstraction/subclassing. A few self-contained modules that hide inner complexity, that are tied together with simple APIs.
//Nick: yes
//- The code should follow simple code formatting guidelines (so that I don’t have to reformating stuff later). I will supply these. It’s really mostly about the use of white-space and when/where to place { }
//Nick: ok
//
//Then I have a few questions:
//- What’s the retry algorithm used?
//
//Nick:
//On each request will be performed:
//Lookup for DNS SRV records and form queue of servers initially ordered by SRV priority and weight parameters. The queue will be stored in memory.
//That would be too many DNS requests which would slow down API calls too much. (In normal cases the app will do multiple small server request simultaneously.) Instead your component should get the DNS SRV records once after app startup and cache them in memory. It should then only refetch after the Time-To-Live (TTL) has expired. We will set TTL to a short enough value to allow frequent enough updates (to cover the case of adding/removing/changing servers); so the component can just look at TTL.
//Nick: good deal
//
//Each server info object will have the following helper parameters:
//priority - fetched from DNS SRV record
//weight  - fetched from DNS SRV record
//retry - counter of sequential failures
//lastfailure - datetime of the last failure (if null then server is considered active)
//
//Alongside we will have these global parameters:
//What do you mean with ‘global’? Don’t we need parameters per API call; or is that what you mean?
//Nick: yes,I meant per API call for previous_retry_time, timeout_retry  and the max* limit parameters will be static to the extension class.
//
//max_retry_attempts - max retry attempts per server
//max_timeout_attempts - max retries when max_retry_attempts is reached
//previous_retry_time - used to estimate next retry time
//timeout_retry - current timeouts when all servers retry reach max_retry_attempts
//Small remark: All variable/property/function names should be camel-case: maxRetryAttempts, …
//Nick: ok
//
//Failure consideration:
//Based on HTTP response status codes consider if it’s a 5xx server error than no retry is performed.
//Otherwise based on reachability results consider connectivity issue and if so, then no retry is performed.
//Are you saying here that no retry will be done based on reachability? As I said earlier, reachability may not be used as a condition for yes/no retry. I can imagine only one purpose of reachability: Doing a DNS refetch when TTL (or X) has already expired: The situation where you know it’s time to refetch but the refetch attempt failed because internet connection was down (there’s one particular iOS/AFNetworking code that indicates this, I will look that up.) You’ll then start waiting until you receive a positive reachability notification, and try again on that trigger.
//Nick: ok,we won’t depend on any reachablity services. However, we might have false failure results in case of no connectivity, but even then in worst case we may just end up using not top priority available server.
//
//In any other casses when failure is fired in the AFNetworking and status codes are 4xx a failure is considered and below is described the algorithm which handles it.
//What happens in that case? (I assume this is described below?)
//BTW, very good you’ll be looking at HTTP codes!
//
//The third thing is the delegate method that you must call, with which I will check the (id)content of the reply.
//
//If a failure happen the component will get notified and start the following retry mechanism:
//1. Get the first server from the queue and checks the retry counter. If retry > max_retry_attempts goes to step 6, else continues with step 2.
//2. Get the first server from the queue and tries to reach it. If not reachable goes to next step, else step 4.
//How do you suggest this reachabilty is determined? Again, the reachability module may not be used because it’s not accurate. Or is this done by a retry? (If so, using the term ‘reachable’ here is confusing.) Nick: I meant a request retry.
//3. Increment the retry parameter and lastfailure. Reorder the queue by  lastfailure (desc),retry, priority, weight. Goes to step 1.
//4.  Clear timeout_retry, previous_retry_time , server’s retry and lastfailure parameters. Reorder the queue by  lastfailure (desc),retry, priority, weight and continues with next step.
//5. Return successful response. (end)
//6. Increment timeout_retry. If timeout_retry > max_timeout_attempts goes to step 8, else goes to next step.
//7. Wait for retry timeout (incremential) and clears servers retry parameter. Check reachability and if connection available goes to step 1, else goes to step 6.
//8. Return last (4xx code) response. (end)
//
//Because a few things are still unclear I can’t fully estimate the overall behaviour. But I get the impression that a lot of retries might be done under certain circumstances.
//As said above, I also seem to be missing retry parameters per API call. At least there should be an overall timeout per call, after which the retrying stops.
//Then I likes the “Retry Delays During Failover“ timing scheme in you last link below. Will you implement this? I think calculation of the retry time should be encapsulated so it’s easy to see and change.
//Nick: I suggest timeout_retry (or timeoutRetry) to be used as terminal for the algorithm (step7 > step8 > end)
//
//Please describe what happens in a few example cases with say 5 or more (until the repetitive behaviour of the mechanism becomes clear) API calls:
//A. 3 servers of which all 3 fail.
//Nick: The calls will be retried for all the servers based on their priority untill all of them first hit maxRetryAttempts per server and then all together hit timeoutRetry limit and then a failure is returned.
//B. 3 servers of which 1 fails.
//Nick: If the first server fails it will be reordered with the least availability and the request will retried for the second one.If it happens for future request within the app lifecycle to fail then that initially failed server won’t be consider available and will be asked lastly.
//C. 3 server of which none fails.
//Nick: So no failure is considered (catched) by the extension and nothing will be invoked.
//D. 3 servers of which one fails, but then no longer fails after one failure.
//Nick: Already covered in case B. The failed server will have least priority to be asked after one failure.
//Then, how would the outcome of these examples change with an increasing number of servers? And, is there always round-robin between the working servers?
//Nick: The more servers the more attempts to be made, but I imagine we could balance the max retry and and timeout parameters to ensure the same time for failure/successful response.
//Can you give a 1000% guarantee there’s never infinite looping of this algorithm? And that it always has an outcome (which may be a failire returned to the app of course) after a maximum preset timeout?
//Nick: Since we have logical end of an 8 steps algorithm I am sure that with proper implementation we would have the same result.
//
//- How does it all work together with reachability, ...? Should be checked in order to trigger failover
//- What sources were used to come up with this solution? (As I suggested on Skype, the chosen method should be a proven one.)
//Nick:
//http://msdn.microsoft.com/en-us/library/hh680901%28v=pandp.50%29
//http://en.wikipedia.org/wiki/Weighted_round_robin
//http://technet.microsoft.com/en-us/library/ms365783(v=sql.105).aspx
//
//- What did or does Apple say/suggest? (On Skype I said that Apple should be asked.)
//Alex: We didn’t ask them yet. We did extensive search of this issue and couldn’t find anything better than what we are proposing.Let me know if it is neccessary to proceed with raising a support question
//For some reason it’s hard to find information about this what-should-be common issue. Yes, please ask Apple, I’ll pay the 30euro (plus time of course). I would not be surprized if they have no answer and will return the techinical support credit.
//
//Alex: Cool, Kees, could you please phrase the question for us? This will be easier.
//
//
//Overall, it looks very good! Let’s try to figure out these last issues/questions and get going then.
//
//Nick: new algorithm
//
//Failure consideration:
//Based on HTTP response status codes consider if it’s a 5xx server error than no retry is performed and the component will return the failure. (calls checkReplyContent with nil/specific content).
//
//In any other casses when failure is fired in the AFNetworking and status codes are 4xx a failure is considered and the retry algorithm handles it.
//
//Component parameters
//timer - measures overall time spent in retrying servers
//This can’t be a ‘compenent parameter’, because time must be kept per API call.
//Nick: correct, it should be per API call
//
//timeout - overall timeout after which failure is returned (static) What do you mean with ‘static’? Nick: by static I mean class parameter and not instance
//serversQueue - static
//okStep - increment step if request went ok (default 1) (static)
//failStep - increment step if request fail (default 3) (static)
//okStep and failStep can be internal parameters only: okStep = always 1, failStep = equal to number of servers.
//Nick: ok
//
//Each server info object will have the following helper parameters:
//priority - fetched from DNS SRV record (lower means more preferred)
//serverHealth - used to sort servers in queue (default = priority) Better name would be ‘order’, instead of ‘serverHealth’. I’ll still use the term ‘serverHealth’ below to not mess up your story. (But use ‘order’ in the code.)
//Nick: ok
//Retry algorithm
//
//0. start timer and goes to next step.
//Do you literally mean start, like with a NSTimer? Because no timer is needed. You just need to save the current time in an NSDate, and then (before each request) check if the time difference between saved time and current time does not exceed the timeout.
//Nick: I didn't mean NSTimer or other particular class since this is pseudo-code and it’s simpler to describe it with a timer. But when it comes to real implementation I find your suggestion appropriate.
//
//
//1. Get the head of the queue and checks the retry counter. If timer > tiimeout goes to step 6, else continues with step 2.
//I assume you mean “if retry count too high, or timer > timeout”? (As I said above, no NSTimer must be used, so of course this “timer > timeout” will be something else then, comparing two NSDate’s.)
//Nick: I agree,thus in the real implementation no NSTimer will be used.
//
//2. Get the head of the queue and retries the request.
//Calls checkReplyContent with the response and if NO is returned OR response is failed goes to next step, else step 4.
//
//3. Increment the retry parameter and serverHealth += priority+failStep . Sort the queue by  serverHealth. Insert the failed server after the last server with less or equeal serverHealth parameter.As discussed DON’T SORT, but instead insert the just used server in the list. Sorting can’t be used because often (with all servers having same priority for example) servers will have the same serverHealth value; it would break round-robin.
//Goes to step 1.
//Nick: Here again due to the pseudo-code description I have used the term sort as inserting in a certain position requires a similar approach. (I have made changes)
//
//4.  Reset timer. Set serverHealth += priority+okStep. Reorder the queue by  serverHealth and continues with next step.
//
//5. Return successful response. (end)
//
//6. Return last (4xx code) response. (end)
//What about the other failures: 5xx, or delegate method says NO?
//Nick: The retry algorithm handles only 4xx code responses. Rest cases are to be covered by the component common logic (see Failure consideration)
//checkReplyContent method is added to step 2 of the retry algorithm.
//
//(Note: Pseudo code with a while and if’s would have been much easier to read than these steps.)
//
//Example when all servers keep failing until the timeout is reached.
//timeout = 2s
//okStep = 1
//failStep= 3
//server 	- priority
//a	- 0
//b 	- 1
//c	- 4
//d	- 5
//
//retry1 : 		a   b   c   d	-> a fails
//serverHealth:	0   1   4   5
//timer:	0.2s
//
//retry2 : 		b   a   c   d	-> b fails
//serverHealth:	1   3   4   5
//timer:	0.5s
//
//retry3 : 		a   c   b   d	-> a fails
//serverHealth:	3   4   4   5
//timer:	0.9s
//
//retry4 : 		c   b   d   a	-> c fails
//serverHealth:	4   4   5   6
//timer:	1.1s
//
//retry5 : 		b   d   a   c	-> b fails
//serverHealth:	4   5   6   7
//timer:	1.4s
//
//retry6 : 		a   b   c   d	-> a fails
//serverHealth:	0   1   4   5
//timer:	1.9s
//
//retry7 : 		d   a   c   b	-> d fails
//serverHealth:	5   6   7   8
//timer:	2.2s
//
//timeout reached => failure returned
//
//- The list of servers is shared between all API calls. Make sure the code using it is MT-safe.
//- Don’t worry about always incrementing these serverHealth values for each request. If you simply use an ‘int’ we’ll never ever reach INT_MAX.
//
//Please confirm that the server list is indeed shared and that serverHealth is incremented all the time. Because you don’t explicitly mention that.
//Nick: Yes, I confirm that this is the case.
//
//Overall, I think it’s a great suggestion/idea of you to use low values (0, 1, …) as DNS priority, and to have 1 as ok increment step! Theoretically the current scheme won’t be perfect probably, but here the simplicity of the algorithm wins and that’s a good thing.
//
//
//
//


#import "AFHTTPRequestOperationManager.h"
#import "FailoverOperation.h"


@protocol FailoverDelegate <NSObject>

- (NSString*)modifyServer:(NSString*)server;

- (BOOL)checkReplyContent:(id)content;

- (NSString*)webUsername;

- (NSString*)webPassword;

@end


@interface FailoverWebInterface : AFHTTPRequestOperationManager

@property (atomic, copy)      NSString*            dnsHost;
@property (atomic, weak)      id<FailoverDelegate> delegate;
@property (nonatomic, assign) NSTimeInterval       timeout;  // Seconds.


+ (FailoverWebInterface*)sharedInterface;

- (NSString*)getServer;

- (void)networkRequestFail:(FailoverOperation*)notificationOperation;

- (void)reorderServersWithSuccess:(BOOL)success;

- (void)getPath:(NSString*)path
     parameters:(id)parameters
        success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
        failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;

- (void)postPath:(NSString*)path
      parameters:(id)parameters
         success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
         failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;

- (void)putPath:(NSString*)path
     parameters:(id)parameters
        success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
        failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;

- (void)deletePath:(NSString*)path
        parameters:(id)parameters
           success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
           failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;

- (void)cancelAllHTTPOperationsWithMethod:(NSString*)method path:(NSString*)path;

@end
