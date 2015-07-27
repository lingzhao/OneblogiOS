//
//  OBObjsViewController.m
//  OneblogiOS
//
//  Created by Terwer Green on 15/7/27.
//  Copyright (c) 2015年 Terwer Green. All rights reserved.
//

#import "OBObjsViewController.h"
#import "Utils.h"

@interface OBObjsViewController ()

@property (nonatomic, assign) BOOL refreshInProgress;

@end

@implementation OBObjsViewController

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _objects = [NSMutableArray new];
        _page = 0;
        _needRefreshAnimation = YES;
        _shouldFetchDataAfterLoaded = YES;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.tableView.backgroundColor = [UIColor themeColor];
    
    _lastCell = [LastCell new];
    [_lastCell addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fetchMore)]];
    self.tableView.tableFooterView = _lastCell;
    
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    _label = [UILabel new];
    _label.numberOfLines = 0;
    _label.lineBreakMode = NSLineBreakByWordWrapping;
    _label.font = [UIFont boldSystemFontOfSize:14];
    
    if (!_shouldFetchDataAfterLoaded) {return;}
    if (_needRefreshAnimation) {
        [self.refreshControl beginRefreshing];
        [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y-self.refreshControl.frame.size.height)
                                animated:YES];
    }
    
    //初始化api
    BOOL apiState=[self setupApi];
    if (!apiState) {
        NSLog(@"api初始化失败，请重新登录。");
        return;
    }
    
    [self fetchObjectsOnPage:0 refresh:YES];
}

#pragma mark - Private

- (BOOL)setupApi {
    if (self.api == nil) {
        //NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
        NSString *xmlrpc = @"http://www.terwer.com/xmlrpc.php";//[def objectForKey:@"mw_xmlrpc"];
        if (xmlrpc) {
            NSString *username = @"terwer";//[def objectForKey:@"mw_username"];
            NSString *password = @"cbgtyw2020";//[def objectForKey:@"mw_password"];
            if (username && password) {
                self.api = [TGMetaWeblogAuthApi apiWithXMLRPCURL:[NSURL URLWithString:xmlrpc] username:username password:password];
            }
        }
        
    }
    
    //api初始化成功
    if (self.api) {
        return YES;
    }else{
        return NO;
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 0;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/



#pragma mark - 刷新

- (void)refresh
{
    _refreshInProgress = NO;
    
    if (!_refreshInProgress) {
        _refreshInProgress = YES;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self fetchObjectsOnPage:0 refresh:YES];
            _refreshInProgress = NO;
        });
    }
}

#pragma mark - 上拉加载更多

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if(scrollView.contentOffset.y > ((scrollView.contentSize.height - scrollView.frame.size.height)))
    {
        [self fetchMore];
    }
}

- (void)fetchMore
{
    if (!_lastCell.shouldResponseToTouch) {return;}
    
    _lastCell.status = LastCellStatusLoading;
    [self fetchObjectsOnPage:++_page refresh:NO];
}


#pragma mark - 请求数据

- (void)fetchObjectsOnPage:(NSUInteger)page refresh:(BOOL)refresh
{
    NSAssert(false, @"Over ride in subclasses");
//    [_manager GET:self.generateURL(page)
//       parameters:nil
//          success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseDocument) {
//              _allCount = [[[responseDocument.rootElement firstChildWithTag:@"allCount"] numberValue] intValue];
//              NSArray *objectsXML = [self parseXML:responseDocument];
//              
//              if (refresh) {
//                  _page = 0;
//                  [_objects removeAllObjects];
//                  if (_didRefreshSucceed) {_didRefreshSucceed();}
//              }
//              
//              if (_parseExtraInfo) {_parseExtraInfo(responseDocument);}
//              
//              for (ONOXMLElement *objectXML in objectsXML) {
//                  BOOL shouldBeAdded = YES;
//                  id obj = [[_objClass alloc] initWithXML:objectXML];
//                  
//                  for (OSCBaseObject *baseObj in _objects) {
//                      if ([obj isEqual:baseObj]) {
//                          shouldBeAdded = NO;
//                          break;
//                      }
//                  }
//                  if (shouldBeAdded) {
//                      [_objects addObject:obj];
//                  }
//              }
//              
//              dispatch_async(dispatch_get_main_queue(), ^{
//                  if (self.tableWillReload) {self.tableWillReload(objectsXML.count);}
//                  else {
//                      if (_page == 0 && objectsXML.count == 0) {
//                          _lastCell.status = LastCellStatusEmpty;
//                      } else if (objectsXML.count == 0 || (_page == 0 && objectsXML.count < 20)) {
//                          _lastCell.status = LastCellStatusFinished;
//                      } else {
//                          _lastCell.status = LastCellStatusMore;
//                      }
//                  }
//                  
//                  if (self.refreshControl.refreshing) {
//                      [self.refreshControl endRefreshing];
//                  }
//                  
//                  [self.tableView reloadData];
//              });
//          }
//          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//              MBProgressHUD *HUD = [Utils createHUD];
//              HUD.mode = MBProgressHUDModeCustomView;
//              HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
//              HUD.detailsLabelText = [NSString stringWithFormat:@"%@", error.userInfo[NSLocalizedDescriptionKey]];
//              
//              [HUD hide:YES afterDelay:1];
//              
//              _lastCell.status = LastCellStatusError;
//              if (self.refreshControl.refreshing) {
//                  [self.refreshControl endRefreshing];
//              }
//              [self.tableView reloadData];
//          }
//     ];
}



@end
